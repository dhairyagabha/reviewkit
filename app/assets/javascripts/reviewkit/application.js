import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import FileNavController from "reviewkit/controllers/file_nav_controller"
import ReviewIndexController from "reviewkit/controllers/review_index_controller"

const application = Application.start()
application.debug = false
application.register("reviewkit--file-nav", FileNavController)
application.register("reviewkit--review-index", ReviewIndexController)

window.Reviewkit ||= {}
window.Reviewkit.Stimulus = application
