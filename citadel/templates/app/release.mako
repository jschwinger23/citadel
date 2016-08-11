<%inherit file="/base.mako"/>
<%namespace name="utils" file="/utils.mako"/>

<%def name="title()">
  ${ release.name } @ ${ release.sha[:7] }
</%def>

<%def name="more_css()">
  .progress-bar {
  -webkit-transition: none !important;
  transition: none !important;
  }
</%def>

<%block name="main">

  <%call expr="utils.panel()">
    <%def name="header()">
      <h3 class="panel-title">Release</h3>
    </%def>
    <h4><a href="${ url_for('app.get_app', name=app.name) }">${ app.name }</a> @ ${ release.short_sha }</h4>
    % if release.image:
      <button class="btn btn-info pull-right" data-toggle="modal" data-target="#add-container-modal">
        <span class="fui-plus"></span> Add Container
      </button>
    % elif g.user.privilege:
      <button class="btn btn-info pull-right" data-toggle="modal" data-target="#add-container-modal">
        <span class="fui-plus"></span> Add Raw Container
      </button>
    % else:
      <button class="btn btn-info pull-right" disabled>
        <span class="fui-plus"></span> Add Container
      </button>
    % endif
  </%call>

  <%call expr="utils.panel()">
    <%def name="header()">
      <h3 class="panel-title">app.yaml</h3>
    </%def>

    <pre>${ appspecs | n }</pre>
  </%call>

  <%call expr="utils.panel()">
    <%def name="header()">
      <h3 class="panel-title">Online Containers: ${ len(containers) }</h3>
    </%def>
    <%utils:container_list containers="${ containers }">
    </%utils:container_list>
  </%call>

</%block>

<%def name="more_body()">

  <%call expr="utils.modal('build-image-modal')">

    <%def name="header()">
      <h3 class="modal-title">Build Image</h3>
    </%def>

    <form id="build-image-form" class="form-horizontal" action="">
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">App</label>
        <div class="col-sm-10">
          <input class="form-control" type="text" name="name" value="${ app.name }" disabled>
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Version</label>
        <div class="col-sm-10">
          <input class="form-control" type="text" name="sha" value="${ release.sha }" disabled>
        </div>
      </div>
    </form>

    <%def name="footer()">
      <button class="btn btn-warning" id="close-modal" data-dismiss="modal"><span class="fui-cross"></span>Close</button>
      <button class="btn btn-info" id="build-image-button"><span class="fui-plus"></span>Go</button>
    </%def>

  </%call>

  <%call expr="utils.modal('add-container-modal')">

    <%def name="header()">
      <h3 class="modal-title">Add Container</h3>
    </%def>

    <form id="add-container-form collapse advance-form-group" class="form-horizontal" action="">
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Release</label>
        <div class="col-sm-10">
          <input class="form-control" type="text" name="release" value="${release.name} / ${release.short_sha}" data-id="${release.id}" disabled>
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Pod</label>
        <div class="col-sm-10">
          <select name="pod" class="form-control">
            % for p in pods:
              <option value="${ p.name }">${ p.name }</option>
            % endfor
          </select>
        </div>
      </div>
      <div class="form-group collapse advance-form-group">
        <label class="col-sm-2 control-label" for="">Node</label>
        <div class="col-sm-10">
          <select class="form-control" name="node">
            <option value="_random">Let Eru choose for me</option>
            % for n in nodes:
              <option value="${ n.name }">${ n.name }</option>
            % endfor
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Entrypoint</label>
        <div class="col-sm-10">
          <select class="form-control" name="entrypoint">
            % for entry in release.specs.entrypoints.keys():
              <option value="${ entry }">${ entry }</option>
            % endfor
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Env</label>
        <div class="col-sm-10">
          <select class="form-control" name="envname">
            % for env in envs:
              <option value="${ env.envname }">${ env.envname }</option>
            % endfor
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Number</label>
        <div class="col-sm-10">
          <input class="form-control" type="number" name="count" value="1">
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Combo</label>
        <div class="col-sm-10">
          <select class="form-control" name="combo">
            % for combo in combos:
              <option value="${combo.label}">${combo.label}: ${combo.cpu} CPU, ${combo.memory_str} Memory</option>
            % endfor
          </select>
        </div>
      </div>
      <div class="form-group collapse advance-form-group">
        <label class="col-sm-2 control-label" for="">Extra Env</label>
        <div class="col-sm-10">
          <input class="form-control" type="text" name="envs" value="" placeholder="例如a=1;b=2;">
        </div>
      </div>
      <div class="form-group">
        <label class="col-sm-2 control-label" for="">Network</label>
        <div class="col-sm-10">
          % for name, cidr in networks.iteritems():
            <label class="checkbox" for="">
              <input type="checkbox" name="network" value="${ name }">${ name } - ${ cidr }
            </label>
          % endfor
        </div>
      </div>
      % if g.user.privilege:
        <div class="form-group collapse advance-form-group">
          <label class="col-sm-2 control-label" for="">Raw</label>
          <div class="col-sm-10">
            <input class="form-control" type="checkbox" name="raw" value="">
          </div>
        </div>
      % endif
    </form>

    <%def name="footer()">
      <button class="btn btn-warning pull-left" data-toggle="collapse" data-target=".advance-form-group">老子搞点高级的</button>
      <button class="btn btn-warning" id="close-modal" data-dismiss="modal"><span class="fui-cross"></span>Close</button>
      <button class="btn btn-info" id="add-container-button"><span class="fui-plus"></span>Go</button>
    </%def>

  </%call>

  <%call expr="utils.modal('container-progress')">
    <%def name="header()">
      <h3 class="modal-title">Please wait...</h3>
    </%def>
    <%def name="footer()">
    </%def>

    <div class="progress">
      <div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aira-valuemax="100">
        <span class="sr-only">Waiting ...</span>
      </div>
    </div>
  </%call>

  <%call expr="utils.modal('build-image-progress')">
    <%def name="header()">
      <h3 class="modal-title">Building Image ...</h3>
    </%def>
    <%def name="footer()">
    </%def>

    <pre id="build-image-pre"></pre>
  </%call>

</%def>

<%def name="bottom_script()">
  <script src="/citadel/static/js/deploy.js" type="text/javascript"></script>
</%def>
