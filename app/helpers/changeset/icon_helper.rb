# frozen_string_literal: true

module Changeset
  module IconHelper
    def changeset_file_icon(class_name: "changeset-file-icon")
      content_tag(
        :svg,
        safe_join([
          tag.path(
            d: "M4.75 1.5h4.9L12.5 4.35v7.9a1.25 1.25 0 0 1-1.25 1.25h-6.5A1.25 1.25 0 0 1 3.5 12.25v-9.5A1.25 1.25 0 0 1 4.75 1.5Z",
            fill: "none",
            stroke: "currentColor",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "stroke-width": "1.1"
          ),
          tag.path(
            d: "M9.5 1.75v2.5H12",
            fill: "none",
            stroke: "currentColor",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "stroke-width": "1.1"
          )
        ]),
        class: class_name,
        viewBox: "0 0 16 16",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        "aria-hidden": "true"
      )
    end

    def changeset_chevron_right_icon(class_name: "changeset-inline-icon")
      content_tag(
        :svg,
        tag.path(
          d: "M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 1 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z",
          "clip-rule": "evenodd",
          "fill-rule": "evenodd"
        ),
        class: class_name,
        viewBox: "0 0 20 20",
        fill: "currentColor",
        "aria-hidden": "true"
      )
    end

    def changeset_pencil_icon(class_name: "changeset-inline-icon")
      content_tag(
        :svg,
        safe_join([
          tag.path(
            d: "M16.862 3.487a2.25 2.25 0 0 0-3.182 0l-8.25 8.25a2.25 2.25 0 0 0-.588 1.06l-.74 3.333a.75.75 0 0 0 .895.895l3.333-.74a2.25 2.25 0 0 0 1.06-.588l8.25-8.25a2.25 2.25 0 0 0 0-3.182Z",
            fill: "none",
            stroke: "currentColor",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "stroke-width": "1.5"
          ),
          tag.path(
            d: "m12.75 4.5 2.75 2.75",
            fill: "none",
            stroke: "currentColor",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "stroke-width": "1.5"
          )
        ]),
        class: class_name,
        viewBox: "0 0 20 20",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        "aria-hidden": "true"
      )
    end

    def changeset_trash_icon(class_name: "changeset-inline-icon")
      content_tag(
        :svg,
        safe_join([
          tag.path(
            d: "M7.5 2.75h5a.75.75 0 0 1 .75.75V5h3.25a.75.75 0 0 1 0 1.5h-.69l-.63 9.12A2.25 2.25 0 0 1 12.94 17.75H7.06a2.25 2.25 0 0 1-2.24-2.13L4.19 6.5H3.5a.75.75 0 0 1 0-1.5h3.25V3.5a.75.75 0 0 1 .75-.75Z",
            fill: "none",
            stroke: "currentColor",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "stroke-width": "1.5"
          ),
          tag.path(
            d: "M8.5 8.25v5.5M11.5 8.25v5.5",
            fill: "none",
            stroke: "currentColor",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "stroke-width": "1.5"
          )
        ]),
        class: class_name,
        viewBox: "0 0 20 20",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        "aria-hidden": "true"
      )
    end
  end
end
