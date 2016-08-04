# coding: utf-8

import json
import logging
from flask import g, request, abort

from citadel.ext import core
from citadel.libs.utils import with_appcontext
from citadel.libs.view import create_ajax_blueprint, DEFAULT_RETURN_VALUE
from citadel.views.helper import bp_get_app, bp_get_balancer
from citadel.action import create_container, remove_container, action_stream, ActionError, upgrade_container

from citadel.models.app import AppUserRelation, Release
from citadel.models.env import Environment
from citadel.models.container import Container
from citadel.models.loadbalance import (Route, ELBInstance, add_route_analysis,
                                        delete_route_analysis, refresh_routes)


bp = create_ajax_blueprint('ajax', __name__, url_prefix='/ajax')
log = logging.getLogger(__name__)


@bp.route('/app/<name>/delete-env', methods=['POST'])
def delete_app_env(name):
    envname = request.form['env']
    app = bp_get_app(name, g.user)
    env = Environment.get_by_app_and_env(app.name, envname)
    if env:
        log.info('Env [%s] for app [%s] deleted', envname, name)
        env.delete()
    return DEFAULT_RETURN_VALUE


@bp.route('/app/<name>/online-entrypoints', methods=['GET'])
def get_app_online_entrypoints(name):
    app = bp_get_app(name, g.user)
    return app.get_online_entrypoints()


@bp.route('/app/<name>/online-pods', methods=['GET'])
def get_app_online_pods(name):
    app = bp_get_app(name, g.user)
    return app.get_online_pods()


@bp.route('/app/<name>/backends')
def get_app_backends(name):
    return {}


@bp.route('/release/<release_id>/deploy', methods=['POST'])
def deploy_release(release_id):
    release = Release.get(release_id)
    if not release:
        abort(404, 'Release %s not found' % release_id)

    if not (release.specs and release.specs.entrypoints):
        abort(404, 'Release %s has no entrypoints')

    podname = request.form['podname']
    entrypoint = request.form['entrypoint']
    cpu = request.form.get('cpu', type=float, default=0)
    count = request.form.get('count', type=int, default=1)
    envname = request.form.get('envname', '')
    envs = request.form.get('envs', '')
    nodename = request.form.get('nodename', '')
    raw = request.form.get('raw', type=int, default=0)

    if raw and not g.user.privilege:
        abort(400, 'Raw deploy only supported for admins')

    # 比较诡异, jQuery传个list是这样的...
    networks = request.form.getlist('networks[]')

    if nodename == '_random':
        nodename = ''
    extra_env = [env.strip() for env in envs.split(';')]
    extra_env = [env for env in extra_env if env]

    # 这里来的就都走自动分配吧
    networks = {key: '' for key in networks}

    try:
        q = create_container(release.app.git, release.sha, podname, nodename, entrypoint, cpu, count, networks, envname, extra_env, bool(raw))
    except ActionError as e:
        log.error('error when creating container: %s', e.message)
        return {'error': e.message}

    for line in action_stream(q):
        m = json.loads(line)
        if not m['success']:
            log.error('error when creating container: %s', m['error'])
            continue

    return DEFAULT_RETURN_VALUE


@bp.route('/release/<release_id>/entrypoints')
def get_release_entrypoints(release_id):
    release = Release.get(release_id)
    if not release:
        abort(404, 'Release %s not found' % release_id)

    if not (release.specs and release.specs.entrypoints):
        abort(404, 'Release %s has no entrypoints')

    return release.specs.entrypoints.keys()


@bp.route('/rmcontainer', methods=['POST'])
def remove_containers():
    container_ids = request.form.getlist('container_id')
    try:
        remove_container(container_ids)
    except ActionError as e:
        log.error('error when removing containers: %s', e.message)
        return {'error': e.message}
    return DEFAULT_RETURN_VALUE


@bp.route('/pods')
def get_all_pods():
    return core.list_pods()


@bp.route('/pod/<name>/nodes')
def get_pod_nodes(name):
    return core.get_pod_nodes(name)


@bp.route('/loadbalance', methods=['POST'])
def create_loadbalance():
    release_id = request.form['releaseid']
    release = Release.get(release_id)
    if not release:
        abort(404, 'Release %s not found' % release_id)

    podname = request.form['podname']
    entrypoint = request.form['entrypoint']
    name = request.form['name']
    cpu = request.form.get('cpu', type=float, default=1)
    nodename = request.form.get('nodename', '')
    comment = request.form.get('comment', '')
    envs = request.form.get('env', '')

    if nodename == '_random':
        nodename = None

    extra_env = ['ELBNAME=%s' % name]
    for env in envs.split(';'):
        env = env.strip()
        if not env:
            continue
        extra_env.append(env)

    try:
        q = create_container(release.app.git, release.sha, podname, nodename, entrypoint, cpu, 1, {}, 'prod', extra_env)
    except ActionError as e:
        log.error('error when creating ELB: %s', e.message)
        return {'error': e.message}

    @with_appcontext
    def _stream_consumer(q):
        for line in action_stream(q):
            m = json.loads(line)
            if not m['success']:
                log.error('error when creating ELB: %s', m['error'])
                continue

            container = Container.get_by_container_id(m['id'])
            if not container:
                continue

            ips = container.get_ips()
            elb = ELBInstance.create(ips[0], g.user.id, container.container_id, name, comment)
            yield elb

    for elb in _stream_consumer(q):
        log.info('ELB [%s] created', elb.name)
    return DEFAULT_RETURN_VALUE


@bp.route('/loadbalance/<id>/remove', methods=['POST'])
def remove_loadbalance(id):
    elb = bp_get_balancer(id)
    try:
        q = remove_container([elb.container_id])
    except ActionError as e:
        return {'error': e.message}

    # TODO 这里是同步的... 会不会太久
    for line in action_stream(q):
        m = json.loads(line)
        if m['success'] and elb.container_id == m['id']:
            log.info('ELB [%s] deleted', elb.name)
            elb.delete()
    return DEFAULT_RETURN_VALUE


@bp.route('/loadbalance/<name>/refresh', methods=['POST'])
def refresh_loadbalance(name):
    elbs = ELBInstance.get_by_name(name)
    if not elbs:
        abort(404, 'No ELB [%s] found' % name)

    refresh_routes(name)
    log.info('ELB [%s] refreshed', name)
    return DEFAULT_RETURN_VALUE


@bp.route('/loadbalance/route/<id>/remove', methods=['POST'])
def delete_lbrecord(id):
    route = Route.get(id)
    if not route:
        abort(404, 'Route %d not found' % id)

    route.delete()
    log.info('Route [%s] for ELB [%s] deleted', id, route.elbname)
    return DEFAULT_RETURN_VALUE


@bp.route('/loadbalance/record/<id>/analysis', methods=['PUT', 'DELETE'])
def switch_lbrecord_analysis(id):
    route = Route.get(id)
    if not route:
        abort(404, 'Route %d not found' % id)

    if request.method == 'PUT':
        add_route_analysis(route)
    elif request.method == 'DELETE':
        delete_route_analysis(route)
    return DEFAULT_RETURN_VALUE


@bp.route('/admin/revoke-app', methods=['POST'])
def revoke_app():
    user_id = request.form['user_id']
    name = request.form['name']
    AppUserRelation.delete(name, user_id)
    return DEFAULT_RETURN_VALUE


@bp.before_request
def access_control():
    # loadbalance和admin的不是admin就不要乱搞了
    if not g.user.privilege and (request.path.startswith('/ajax/admin') or request.path.startswith('/ajax/loadbalance')):
        abort(403, 'Must be admin')


@bp.route('/upgrade-container', methods=['POST'])
def upgrade_container_view():
    container_ids = request.form.getlist('container_id')
    release_sha = request.form['release']
    upgrade_container(container_ids, repo=None, sha=release_sha)
    return DEFAULT_RETURN_VALUE