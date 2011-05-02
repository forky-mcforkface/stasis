# Root controller
# ---------------

# Before

before 'index.html.haml' do
  @before_index_literal = :root
end

before /index\.html/ do
  @before_index_regexp = :root
end

before do
  @before_all = :root
end

before 'fail' do
  @fail = true
end

before /fail/ do
  @fail = true
end

# Destination

destination 'rename_controller.html.haml' => 'renamed_controller.html'
destination 'rename_to_subdirectory.html.haml' => 'subdirectory/renamed_to_subdirectory.html'

before 'rename_action.html.haml' do
  destination 'renamed_action.html'
end

# Helpers

helpers do
  def helper
    :root
  end
end

# Ignore

ignore /\/_.*/

# Layout

layout 'layout_controller.html.haml' => 'layout.html.haml'
layout 'layout_controller_from_subdirectory.html.haml' => 'subdirectory/layout.html.haml'

before 'layout_action.html.haml' do
  layout 'layout.html.haml'
end

before 'layout_action_from_subdirectory.html.haml' do
  layout 'subdirectory/layout.html.haml'
end

# Priority

priority 'subdirectory/rename_to_root.html.haml' => 1
priority 'index.html.haml' => -1

before do
  $render_order ||= []
  $render_order << _[:path]
end