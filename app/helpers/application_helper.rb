module ApplicationHelper
  def active?(css_class, url_parameters)
    current_page?(url_parameters) ? css_class : ''
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.permit(:status, :sort, :direction, :search, :last_name, :first_name, :record_id, :email, :assignment_status, :registration_status, :biospecimens_location, :paired_organization, :paried_site).merge({ sort: column, direction: direction }), { class: css_class }
  end

  def validation_errors?(object, field_name)
    object.errors.messages[field_name].any?
  end

  def format_validation_errors(object, field_name)
    if object.errors.any?
      if !object.errors.messages[field_name].blank?
        object.errors.messages[field_name].map(&:humanize).join(". ")
      end
    end
  end
end