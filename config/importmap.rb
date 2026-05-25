# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@stimulus-components/rails-nested-form", to: "@stimulus-components--rails-nested-form.js" # @5.0.0
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4
pin "chart.js" # @4.5.1
pin "chartkick" # @5.0.1
# pin "chartkick", to: "chartkick.js"
# pin "Chart.bundle", to: "Chart.bundle.js"
