class Dashing.Status extends Dashing.Widget
  onData: (data) ->
    if data.text
      className = ""
      switch data.text.toLowerCase()
        when "passed" then className = "passed"
        when "failed" then className = "failed"
        when "work in progress" then className = "wip"
        when "blocked" then className = "blocked"
        when "retest" then className = "retest"
        when "skipped" then className = "skipped"

      $(@get('node')).attr 'class', (i, c) ->
        c.replace /\bstatus-\$+/g, ''

      $(@get('node')).addClass "status-#{className}"