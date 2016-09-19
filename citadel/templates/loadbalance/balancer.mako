<%inherit file="/base.mako"/>
<%namespace name="utils" file="/utils.mako"/>

<%def name="title()">Balancer ${ name }</%def>

<%block name="main">

  <%call expr="utils.panel()">
    <%def name="header()">
      <h3 class="panel-title">"${ name }" Instances</h3>
    </%def>

    <table class="table">
      <thead>
        <tr>
          <th>IP</th>
          <th>ContainerID</th>
          <th>Operation</th>
        </tr>
      </thead>
      <tbody>
        % for elb in elbs:
          <tr>
            <td><a href="http://${elb.ip}/__erulb__/upstream" target="_blank">${elb.ip}</a></td>
            <td><span class="label label-${'success' if elb.is_alive() else 'danger'}">${elb.container_id}</span></td>
            <td><a class="btn btn-xs btn-warning" href="#" data-id="${elb.id}" name="delete-balancer"><span class="fui-trash"></span> Remove</a></td>
          </tr>
        % endfor
      </tbody>
    </table>
    <button class="btn btn-info btn-xs" id="refresh-btn" data-name="${name}"><span class="fui-info-circle"></span> Refresh Routes</button>
  </%call>

  <%call expr="utils.panel()">
    <%def name="header()">
      <h3 class="panel-title">${ name } : Domain And Rules</h3>
    </%def>

    <table class="table">
      <thead>
        <tr>
          <th>Domain</th>
          <th>App</th>
          <th>Operations</th>
        </tr>
      </thead>
      <tbody>
        % for rule in rules:
          <tr>
            <td>${ rule.domain }</td>
            <td>${ rule.appname }</td>
            <td>
              <a class="btn btn-xs btn-info" href="${ url_for('loadbalance.rule', name=name, domain=rule.domain) }" name="get-rule">View</a>
              <form style=" display:inline!important;" action="${ url_for('loadbalance.delete_rule', name=name) }" method="POST">
                <input name="domain" value="${ rule.domain }" type="hidden">
                <button class="btn btn-xs btn-warning" type="submit">嫑了</button>
              </form>
              <a class="btn btn-xs btn-info" href="${ url_for('loadbalance.edit_rule', name=name, domain=rule.domain) }", name="edit-rule">Edit</a>
            </td>
          </tr>
        % endfor
      </tbody>
    </table>

  </%call>

  <ul class="nav nav-tabs" id="add-rule-form">
    <li role="presentation" class="active"><a class="btn" data-target="#add-general-rule" data-toggle="tab"> Simple </a></li>
    <li role="presentation"><a class="btn" data-target="#add-rule" data-toggle="tab"> Advanced </a></li>
  </ul>

  <div class="tab-content">

    <br>

    <div class="col-md-8 col-md-offset-2 tab-pane active" id="add-general-rule">
      <form class="form-horizontal" action="${ url_for('loadbalance.add_general_rule', name=name) }" method="POST">
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">App Name</label>
          <div class="col-sm-10">
            <select id="" class="form-control" name="appname">
              % for app in all_apps:
                <option value="${ app.name }">${ app.name }</option>
              % endfor
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">Entrypoint</label>
          <div class="col-sm-10">
            <% entrypoints = all_apps[0].get_online_entrypoints() %>
            <select id="" class="form-control" name="entrypoint">
              % for e in entrypoints:
                <option value="${ e }">${ e }</option>
              % endfor
              <option value="_all">_all</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">Podname</label>
          <div class="col-sm-10">
            <% pods = all_apps[0].get_online_pods() %>
            <select id="" class="form-control" name="podname">
              % for p in pods:
                <option value="${ p }">${ p }</option>
              % endfor
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">Domain</label>
          <div class="col-sm-10">
            <input class="form-control" type="text" name="domain">
          </div>
        </div>
        <div class="form-group">
          <div class="col-sm-10 col-sm-offset-2">
            <button class="btn btn-info" type="submit"><span class="fui-plus"></span> Add</button>
          </div>
        </div>
      </form>
    </div>

    <div class="col-md-8 col-md-offset-2 tab-pane" id="add-rule">
      <form class="form-horizontal" action="${url_for('loadbalance.add_rule', name=name)}" method="POST">
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">App Name</label>
          <div class="col-sm-10">
            <select id="" class="form-control" name="appname">
              % for app in all_apps:
                <option value="${ app.name }">${ app.name }</option>
              % endfor
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">Domain</label>
          <div class="col-sm-10">
            <input class="form-control" type="text" name="domain">
          </div>
        </div>
        <div class="form-group">
          <label class="col-sm-2 control-label" for="">Rule</label>
          <div class="col-sm-10">
            <input class="form-control" type="text" name="rule">
          </div>
        </div>
        <div class="form-group">
          <div class="col-sm-10 col-sm-offset-2">
            <button class="btn btn-info" type="submit"><span class="fui-plus"></span> Add</button>
          </div>
        </div>
      </form>
    </div>

  </div>

</%block>

<%def name="bottom_script()">
  <script src="/citadel/static/js/balancer.js" type="text/javascript"></script>
  <script src="/citadel/static/js/add-loadbalance.js" type="text/javascript"></script>
</%def>