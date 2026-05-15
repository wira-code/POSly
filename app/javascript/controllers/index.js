// Import and register all your controllers from the importmap via controllers/**/*_controller
// import { application } from "controllers/application"
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
// eagerLoadControllersFrom("controllers", application)

import { Application } from "@hotwired/stimulus"
import NestedForm from "@stimulus-components/rails-nested-form"

const application = Application.start()
// บรรทัดนี้สำคัญมาก เพื่อให้ data-controller="nested-form" ทำงานได้
application.register("nested-form", NestedForm)
