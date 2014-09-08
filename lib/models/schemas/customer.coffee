Schema2.customers = new SimpleSchema
#co the luu mang [String] tai [0] la merchant tao, [1] la parent[0], [2] parent [1]
  parentMerchant:
    type: String
    optional: true

  currentMerchant:
    type: String
    optional: true

  areaMerchant:
    type: String
    optional: true

  name:
    type: String

  company_name:
    type: String
    optional: true

  phone:
    type: String

  address:
    type: String

  email:
    type: String

  sex:
    type: Boolean

  version: { type: Schema.Version }

Schema.add 'customers'
