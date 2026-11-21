# The ⋯ menu of a thing that can be edited and deleted (a set, a logged exercise, a split, a workout day,
# an exercise of the catalogue): actions_menu with menu_link and menu_delete items.
module ActionsMenuHelper
  # The ⋯ button wherever something can be edited and deleted: it opens a menu of the items given in
  # the block (menu_link, menu_delete). Fixed positioning lets the menu out of a scrolling table.
  def actions_menu(name, &)
    label = "Actions for #{name}"
    toggle = tag.button(icon_tag("ellipsis"), type: "button", class: "btn btn-link btn-sm actions-toggle", title: label,
                                              aria: { expanded: false, label: },
                                              data: { bs_toggle: "dropdown", bs_popper_config: { strategy: "fixed" }.to_json })
    tag.div(toggle + tag.ul(capture(&), class: "dropdown-menu dropdown-menu-end"), class: "dropdown actions-menu")
  end

  def menu_link(label, path, icon: "pen", **)
    tag.li(link_to(safe_join([icon_tag(icon), label], " "), path, class: "dropdown-item", **))
  end

  def menu_button(label, path, icon:, method: :patch)
    tag.li(button_to(path, method:, class: "dropdown-item") { safe_join([icon_tag(icon), label], " ") })
  end

  # Deleting is an × everywhere, and asks first when confirm is given.
  def menu_delete(label, path, confirm: nil, **)
    form = { data: { turbo_confirm: confirm }.compact }
    tag.li(button_to(path, method: :delete, class: "dropdown-item text-danger", form:, **) do
      safe_join([icon_tag("xmark"), label], " ")
    end)
  end

  def icon_tag(name)
    tag.i(class: "fa-solid fa-#{name}", aria: { hidden: true })
  end
end
