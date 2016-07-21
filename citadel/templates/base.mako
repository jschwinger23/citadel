<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>${ self.title() } · citadel </title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Le styles -->
    <link href="/citadel/static/img/favicon.jpg" rel="shortcut icon">
    <link href="/citadel/static/css/bootstrap.min.css" rel="stylesheet" type="text/css">
    <link href="/citadel/static/css/flat-ui.min.css" rel="stylesheet" type="text/css">
    <script src="/citadel/static/js/jquery.min.js"></script>
    <script src="/citadel/static/js/flat-ui.min.js"></script>
    <script src="/citadel/static/js/common.js"></script>
    ${ self.more_header() }
    <style>
      ${ self.more_css() }
      nav.navbar {border-radius: 0!important;}
    </style>
    <!-- COLLECTED CSS -->
  </head>

  <body>

    <%block name="nav">
      <!-- Docs master nav -->
      <nav class="navbar navbar-inverse" role="navigation">
      <div class="navbar-header">
        <a href="${ url_for('app.index') }" class="navbar-brand">citadel</a>
      </div>
      <div class="collapse navbar-collapse">
        <ul class="nav navbar-nav">
          <li class="${ 'active' if request.path.startswith('/app') else '' }">
          <a href="${ url_for('app.index') }"><span class="fui-list-numbered"></span> App List</a>
          </li>
          % if g.user and g.user.privilege:
            <li class="${ 'active' if request.path.startswith('/loadbalance') else '' }">
            <a href="${ url_for('loadbalance.index') }"><span class="fui-windows"></span> Load Balance</a>
            </li>

            <li class="dropdown ${ 'active' if request.path.startswith(url_for('admin.index')) else '' }">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                <span class="fui-eye"></span> Admin Area
              </a>
              <ul class="dropdown-menu">
                <li class="${ 'active' if request.path.startswith(url_for('admin.images')) else '' }">
                <a href="${ url_for('admin.images') }"><span class="fui-document"></span> Base Images</a>
                </li>
                <li class="divider"></li>
                <li class="${ 'active' if request.path.startswith(url_for('admin.users')) else '' }">
                <a href="${ url_for('admin.users') }"><span class="fui-user"></span> Users</a>
                </li>
                <li class="divider"></li>
                <li class="${ 'active' if request.path.startswith(url_for('admin.pods')) else '' }">
                <a href="${ url_for('admin.pods') }"><span class="fui-list-thumbnailed"></span> Pods</a>
                </li>
              </ul>
            </li>
          % endif
        </ul>
        <ul class="nav navbar-nav navbar-right">
          <li class="dropdown">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown">${  g.user and g.user.name or u'你谁啊' } <b class="caret"></b></a>
          <ul class="dropdown-menu">
            % if g.user:
              <li><a href="${ url_for('user.logout') }"><span class="fui-power"></span> 再贱</a></li>
            % else:
              <li><a href="${ url_for('user.login') }"><span class="fui-user"></span> 大爷来玩啊</a></li>
            % endif
          </ul>
          </li>
        </ul>
      </div>
      </nav>
    </%block>

    <!-- Docs page layout -->
    <div class="bs-header" id="content">
      <div class="container">
        ${ self.more_content_header() }
      </div>
    </div>

    <div class="container bs-docs-container">
      <div class="row">
        <%block name="main"></%block>
      </div>
    </div>

    ${ self.more_body() }

    <footer class="footer container">
    ${ self.footer() }
    </footer>

    ${ self.bottom_script() }
  </body>
</html>

<%def name="more_css()"></%def>
<%def name="more_header()"></%def>
<%def name="title()">Hall</%def>
<%def name="more_body()"></%def>
<%def name="footer()"></%def>
<%def name="bottom_script()"></%def>
<%def name="more_content_header()"></%def>