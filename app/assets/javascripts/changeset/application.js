import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import FileNavController from "changeset/controllers/file_nav_controller"
import ReviewIndexController from "changeset/controllers/review_index_controller"

const application = Application.start()
application.debug = false
application.register("changeset--file-nav", FileNavController)
application.register("changeset--review-index", ReviewIndexController)

window.Changeset ||= {}
window.Changeset.Stimulus = application
