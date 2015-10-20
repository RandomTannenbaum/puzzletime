# encoding: utf-8

require 'test_helper'

class EditOrderTest < ActionDispatch::IntegrationTest
  setup :login

  teardown :reset_crm

  test 'create order contacts fields' do
    assert has_no_field?('order_order_contacts_attributes_0_contact_id_or_crm')
    assert_no_selector("a[data-object-class='order-contact'].remove_nested_fields_link")

    click_add_contact
    assert find_field('order_order_contacts_attributes_0_contact_id_or_crm', visible: false)[:class].include?('selectized')
    assert_selector("a[data-object-class='order_contact'].remove_nested_fields_link", count: 1)

    click_add_contact
    assert find_field('order_order_contacts_attributes_1_contact_id_or_crm', visible: false)[:class].include?('selectized')
    assert_selector("a[data-object-class='order_contact'].remove_nested_fields_link", count: 2)
  end

  test 'EDIT without crm, contacts are populated according to client' do
    click_add_contact
    assert_selector('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize = find('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize.find('.selectize-input').click # populate & open dropdown
    assert selectize.has_selector?('.selectize-dropdown-content .option', count: 2)
  end

  test 'EDIT without crm, without contacts' do
    Contact.destroy_all
    visit edit_order_path(order)
    click_add_contact
    assert_selector('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize = find('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize.find('.selectize-input').click # populate & open dropdown
    assert selectize.has_no_selector?('.selectize-dropdown-content .option')
  end

  test 'EDIT with crm, contacts are populated according to client' do
    contacts(:puzzle_rava).update!(crm_key: '1234')
    setup_crm_contacts
    visit edit_order_path(order)
    click_add_contact
    assert_selector('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize = find('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize.find('.selectize-input').click # populate & open dropdown
    assert selectize.has_selector?('.selectize-dropdown-content .option', count: 3)
  end

  test 'EDIT with crm, without contacts' do
    Contact.destroy_all
    setup_crm_contacts([])
    visit edit_order_path(order)
    click_add_contact
    assert_selector('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize = find('#order_order_contacts_attributes_0_contact_id_or_crm + .selectize-control')
    selectize.find('.selectize-input').click # populate & open dropdown
    assert selectize.has_no_selector?('.selectize-dropdown-content .option')
  end

  test 'order with worktimes has disabled destroy link' do
    visit edit_order_path(order)
    assert find('a.disabled', text: 'Löschen')
    assert has_no_link?('Löschen', href: order_path(order))
  end

  test 'order without worktimes has active destroy link' do
    visit edit_order_path(order_without_worktimes)
    assert has_link?('Löschen', href: order_path(order_without_worktimes))
    assert refute_selector('a.disabled', text: 'Löschen')
  end

  private

  def click_add_contact
    find("a.add_nested_fields_link[data-object-class='order_contact']").click
  end

  def login
    login_as(:mark, edit_order_path(order))
  end

  def order
    orders(:puzzletime)
  end

  def order_without_worktimes
    orders(:hitobito_demo)
  end

  def setup_crm_contacts(contacts = nil)
    contacts ||= [
      { firstname: 'Andreas', lastname: 'Rava', crm_key: 1234 },
      { firstname: 'Hans', lastname: 'Müller', crm_key: 5678 }
    ]
    Crm.instance = Crm::Highrise.new
    Crm.instance.expects(:find_client_contacts).returns(contacts)
  end

  def reset_crm
    Crm.instance = nil
  end
end
