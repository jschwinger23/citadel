<%!
  from citadel.models.gitlab import get_project
%>

<%def name="container_list(containers)">
  <%def name="header()">
    <h3 class="panel-title">Online Containers: ${ len(containers) }</h3>
  </%def>

  <table class="table">
    <thead>
      <tr>
        <th><input type="checkbox" id="check-all"></th>
        <th>ID</th>
        <th>Name</th>
        <th>Version</th>
        <th>Location</th>
        <th>Network</th>
        <th>CPU</th>
        <th>Entrypoint</th>
        <th>Env</th>
        <th>Status</th>
        <th>Operation</th>
      </tr>
    </thead>
    <tbody>
      % for c in containers:
        <tr>
          <td><input name="container-id" type="checkbox" value="${ c.container_id }"></td>
          <td>
            <a href='javascript://'
              data-placement='right'
              data-toggle="popover"
              rel='popover'
              data-html='true'
              data-original-title='钻进去看看'
              data-content="<pre><code style='font-size:70%;white-space:nowrap' >ssh ${ g.user.name }@${ c.nodename } -t 'sudo docker-enter ${ c.short_id }'</code></pre>">${ c.short_id }</a>
          </td>
          <td>
            <span data-toggle="tooltip" data-placement="top" title="创建于 ${ c.created }">
              ${ c.appname } / ${ c.ident }
            </span>
          </td>
          <td>${ c.sha[:7] }</td>
          <td>${ c.podname }: ${ c.nodename }</td>
          <td>
            % if c.get_ips():
              % for n in c.get_ips():
                <span class="block-span">${ n }</span>
              % endfor
            % else:
              host / none
            % endif
          </td>
          <td>${ c.cpu_quota or u'0 (共享)'}</td>
          <td>${ c.entrypoint }</td>
          <td>${ c.env }</td>
          <td>
            <% status = c.status() %>
            % if status == 'InRemoval':
              <span class="label label-warning">删除中...</span>
            % else:
              <span class="label label-${ 'success' if status == 'running' else 'danger' }">
                ${ u'运行' if status == 'running' else u'挂了' }
              </span>
            % endif
          </td>
          <td>
            <a name="delete-container" class="btn btn-xs btn-warning" href="#" data-id="${ c.container_id }"><span class="fui-trash"></span> Delete</a>
          </td>
        </tr>
      % endfor
    </tbody>
  </table>

  <button name="delete-all" class="btn btn-warning pull-right"><span class="fui-trash"></span> Delete Chosen</button>
  ${caller.body()}

  <script>

    // enable popover
    $('[rel=popover]').popover();
    // close popover when click outside the popover
    $('body').on('click', function (e) {
    if ($(e.target).data('toggle') !== 'popover' && $(e.target).parents('.popover.in').length === 0) {
      $('[data-toggle="popover"]').popover('hide');
    }
    });

    $('#check-all').change(function(){
      var checked = this.checked;
      $.each($('input[name=container-id]'), function(){
        this.checked = checked;
      });
    });

    $(function(){
      $('[data-toggle="tooltip"]').tooltip();
    });

    $(document).on('click', 'a[name=delete-container]', function(e){
      if (!confirm('确定删除?')) {
        return;
      }
      e.preventDefault();
      var self = $(this);
      var containerId = self.data('id');
      var url = '/ajax/rmcontainer';
      $.post(url, {container_id: containerId}, function(){
        self.parent().parent().remove();
      })
    });

    $('button[name=delete-all]').click(function(e){
      if (!confirm('确定删除?')) {
        return;
      }
      if (!$('input[name=container-id]:checked').length) {
        return;
      }
      e.preventDefault();
      var ids = [];
      var url = '/ajax/rmcontainer';
      $.each($('input[name=container-id]:checked'), function(){
        ids.push('container_id=' + $(this).val());
      });
      $.post(url, ids.join('&'), function(){
        $.each($('input[name=container-id]:checked'), function(){
          $(this).parent().parent().remove();
        });
      })
    });
  </script>
</%def>

<%def name="release_list(releases, app)">
  <%
    project = get_project(app.project_name)
  %>
  <table class="table">
    <thead>
      <tr>
        <th>Version</th>
        <th>Created</th>
        <th>Author</th>
        <th>GitLab Link</th>
        <th>Operation</th>
      </tr>
    </thead>
    <tbody>
      % for v in releases:
        <tr>
          <td><a href="${ url_for('app.get_release', name=v.name, sha=v.sha) }">${ v.sha[:7] }</a></td>
          <td>${ v.created }</td>
          <%
            try:
              commit = project.commits.get(v.sha)
              author = commit.author_name
              message = commit.message
            except:
              author = 'unknown'
              message = 'unknown'
          %>
          <td>
            <span data-toggle="tooltip" data-placement="top" title="${ message }">
              ${ author }
            </span>
          </td>
          <td>
            <a href="${ url_for('app.gitlab_url', name=v.name, sha=v.sha) }" target="_blank">${ v.sha[:7] }</a>
          </td>
          <td>
            % if v.image:
              <a class="btn btn-xs btn-success" href="${ url_for('app.get_release', name=v.name, sha=v.sha) }#add">
                <span class="fui-plus"></span> Add Container
              </a>
            % elif g.user.privilege:
              <a class="btn btn-xs btn-success" href="${ url_for('app.get_release', name=v.name, sha=v.sha) }#add">
                <span class="fui-plus"></span> Add Container With Raw Mode
              </a>
            % else:
              <a class="btn btn-xs btn-success" disabled href="${ url_for('app.get_release', name=v.name, sha=v.sha) }#add">
                <span class="fui-plus"></span> Add Container
              </a>
            % endif
          </td>
        </tr>
      % endfor
    </tbody>
  </table>
</%def>

<%def name="panel(panel_class='info')">
  <div class="panel panel-${panel_class}">
    <div class="panel-heading">
      ${ caller.header() }
    </div>
    <div class="panel-body">
      ${ caller.body() }
    </div>
  </div>
</%def>

<%def name="modal(id, role='dialog')">
  <div class="modal fade" role="${ role }" id="${ id }">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          ${ caller.header() }
        </div>
        <div class="modal-body">
          ${ caller.body() }
        </div>
        <div class="modal-footer">
          ${ caller.footer() }
        </div>
      </div>
    </div>
  </div>
</%def>

<%def name="paginator(start=None, limit=None)">
  <%
    if start is None:
        start = g.start
    if limit is None:
        limit = g.limit
    cur_page = start // limit + 1
    begin = max(cur_page - 3, 1)
    end = cur_page + 3
    prev = 'disabled' if cur_page <= 1 else ''
    prev_num = max((cur_page - 2) * limit, 0)
  %>
  <div>
    <ul class="pagination">
      <li class="previous ${ prev }">
      <a class="fui-arrow-left" href="${ request.base_url }?start=${ prev_num }&limit=${ limit }"></a>
      </li>
      % for i in range(begin, end):
        <li class="${ 'active' if cur_page == i else '' }">
        <a href="${ request.base_url }?start=${ (i-1)*limit }&limit=${ limit }">${ i }</a>
        </li>
      % endfor
      <li class="next">
      <a class="fui-arrow-right" href="${ request.base_url }?start=${ cur_page*limit }&limit=${ limit }"></a>
      </li>
    </ul>
  </div>
</%def>
