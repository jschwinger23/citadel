# coding: utf-8
from webargs.flaskparser import use_args
from citadel.libs.validation import GetContainerSchema
from flask import abort, g

from citadel.libs.view import create_api_blueprint
from citadel.models.container import Container
from citadel.libs.view import user_require


bp = create_api_blueprint('container', __name__, 'container')


@bp.route('/')
@use_args(GetContainerSchema())
@user_require(False)
def get_by(args):
    cs = Container.get_by(**args)
    return cs


@bp.route('/<container_id>')
@user_require(False)
def get_container(container_id):
    try:
        containers = Container.get_by_container_id(container_id)
    except ValueError as e:
        abort(404, str(e))

    if not containers:
        abort(404, 'Container not found: {}'.format(container_id))

    return containers[0]
