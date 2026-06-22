locals {
  webpage_api_routes = [
    "ANY /db",
    "ANY /db/create_schedule",
    "ANY /db/periods",
    "ANY /db/list_periods",
    "ANY /db/create_period",
    "ANY /db/update_period",
    "ANY /db/delete_period_definition",
    "ANY /db/assign_period",
    "ANY /db/add_period",
    "ANY /db/delete_period",
    "ANY /instances",
    "ANY /instances/schedule",
    "ANY /instances/ignore"
  ]

  webpage_api_paths = toset([
    for route in local.webpage_api_routes :
    trimprefix(route, "ANY ")
  ])
}
