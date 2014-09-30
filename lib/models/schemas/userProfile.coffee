Schema2.userProfiles = new SimpleSchema
  creator:
    type: String
    optional: true

  user:
    type: String

  fullName:
    type: String
    optional: true

  dateOfBirth:
    type: Date
    optional: true

  startWorkingDate:
    type: Date
    optional: true

  isRoot:
    type: Boolean

  roles:
    type: [String]
    optional: true

  parentMerchant:
    type: String

  currentMerchant:
    type: String

  currentWarehouse:
    type: String

#--------------------------
  currentOrder:
    type: String
    optional: true

  currentImport:
    type: String
    optional: true

  currentSale:
    type: String
    optional: true

#--------------------------
  currentDeliveryMerchant:
    type: String
    optional: true

  currentDeliveryWarehouse:
    type: String
    optional: true

  currentDeliveryFilter:
    type: Number
    optional: true

  currentDelivery:
    type: String
    optional: true
#---------------------------
  inventoryMerchant:
    type: String
    optional: true

  inventoryWarehouse:
    type: String
    optional: true

  currentInventory:
    type: String
    optional: true

  currentInventoryHistory:
    type: String
    optional: true



