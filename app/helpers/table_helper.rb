#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Defines tables to display a list of entries. The helper methods come in
# different granularities:
# * #plain_table - A basic table for the given entries and attributes using
#   the Crud::TableBuilder.
# * #list_table - A sortable #plain_table for the current +entries+, with the
#   given attributes or default.
# * #crud_table - A sortable #plain_table for the current +entries+, with the
#   given attributes or default and the standard crud action links.
module TableHelper
  # Renders a table for the given entries. One column is rendered for each
  # attribute passed. If a block is given, the columns defined therein are
  # appended to the attribute columns.
  # If entries is empty, an appropriate message is rendered.
  # An options hash may be given as the last argument.
  def plain_table(entries, *attrs, &)
    options = attrs.extract_options!
    add_css_class(options, 'table table-striped table-hover table-condensed')
    builder = options.delete(:builder) || DryCrud::Table::Builder
    builder.table(entries, self, options) do |t|
      t.attrs(*attrs)
      yield t if _block
    end
  end

  # Renders a #plain_table for the given entries.
  # If entries is empty, an appropriate message is rendered.
  def plain_table_or_message(entries, *attrs, &block)
    entries.to_a # force evaluation of relations
    if entries.present?
      content_tag(:div, class: 'unindented') do
        plain_table(entries, *attrs, &block)
      end
    else
      content_tag(:div, ti(:no_list_entries), class: 'table')
    end
  end

  # Same as plain_table_or_message, but wraps table in .unindented
  def unindented_plain_table_or_message(entries, *attrs, &block)
    entries.to_a # force evaluation of relations
    if entries.present?
      content_tag(:div, class: 'unindented') do
        plain_table_or_message(entries, *attrs, &block)
      end
    else
      plain_table_or_message(entries, *attrs, &)
    end
  end

  # Create a table of the +entries+ with the default or
  # the passed attributes in its columns. An options hash may be given
  # as the last argument.
  def list_table(*attrs, &)
    attrs, options = explode_attrs_with_options(attrs, &)
    plain_table_or_message(entries, options) do |t|
      t.sortable_attrs(*attrs)
      yield t if block
    end
  end

  # Create a table of the current +entries+ with the default or the passed
  # attributes in its columns. Edit and destroy actions are added to each row.
  # If attrs are present, the first column will link to the show
  # action. Edit and destroy actions are appended to the end of each row.
  # If a block is given, the column defined there will be inserted
  # between the given attributes and the actions.
  # An options hash for the table builder may be given as the last argument.
  def crud_table(*attrs, &)
    attrs, options = explode_attrs_with_options(attrs, &)
    first = attrs.shift
    plain_table_or_message(entries, options) do |t|
      t.attr_with_show_link(first) if first
      t.sortable_attrs(*attrs)
      yield t if block
      standard_table_actions(t)
    end
  end

  # Adds standard action link columns (edit, destroy) to the given table.
  def standard_table_actions(table)
    table.edit_action_col
    table.destroy_action_col
  end

  private

  def explode_attrs_with_options(attrs, &)
    options = attrs.extract_options!
    if !_block && attrs.blank?
      attrs = default_crud_attrs
    end
    [attrs, options]
  end
end
