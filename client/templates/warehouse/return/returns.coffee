formatSaleReturnSearch = (item) -> "#{item.orderCode} #{}" if item
formatReturnSearch = (item) -> "#{item.returnCode}" if item
formatReturnProductSearch = (item) ->
  "#{item.name} [#{item.skulls}] - [giảm giá: #{Math.round(item.discountPercent*100)/100}% - số lượng: #{item.quality - item.returnQuality}]" if item

returnQuality= ->
  findReturnDetail =_.findWhere(Session.get('currentReturnDetails'),{
    productDetail   : Session.get('currentProductDetail').productDetail
    discountPercent : Session.get('currentProductDetail').discountPercent
  })
  if findReturnDetail
    Session.get('currentProductDetail')?.quality - (Session.get('currentProductDetail')?.returnQuality + findReturnDetail.returnQuality)
  else
    Session.get('currentProductDetail')?.quality - Session.get('currentProductDetail')?.returnQuality

runInitReturnsTracker = (context) ->
  return if Sky.global.returnTracker
  Sky.global.returnTracker = Tracker.autorun ->
    if Session.get('currentWarehouse')
      Session.set "availableSales", Schema.sales.find({warehouse: Session.get('currentWarehouse')._id, status: true, submitted: true, returnLock: false}).fetch()


    if Session.get('availableSales')?.length > 0
      if Session.get('currentProfile')?.currentSale
        Session.set 'currentSale', Schema.sales.findOne(Session.get('currentProfile')?.currentSale)
    else
      Session.set 'currentSale'

    if Session.get('currentSale')
      Session.set 'currentReturn', Schema.returns.findOne({sale: Session.get('currentSale')._id, status: {$ne: 2}})
      Session.set 'currentSaleProductDetails', Schema.saleDetails.find({sale: Session.get('currentSale')._id}).fetch()

    if Session.get('currentSale')?.currentProductDetail
      Session.set 'currentProductDetail', Schema.saleDetails.findOne(Session.get('currentSale')?.currentProductDetail)

    if Session.get('currentReturn')
      Session.set 'currentReturnDetails', Schema.returnDetails.find({return: Session.get('currentReturn')._id}).fetch()
    else
      Session.set 'currentReturnDetails'

    if Session.get('currentProductDetail')
      Session.set 'currentMaxQualityReturn', returnQuality()

Sky.appTemplate.extends Template.returns,
  saleReturn: -> Session.get('currentReturn')
  hideAddReturnDetail: -> return "display: none" if Session.get('currentReturn') and Session.get('currentReturn')?.status != 0
  hideFinishReturn: -> return "display: none" if Session.get('currentReturn')?.status != 0
  hideEditReturn:   -> return "display: none" if Session.get('currentReturn')?.status != 1
  hideSubmitReturn: -> return "display: none" if Session.get('currentReturn')?.status != 1

  rendered: ->
    runInitReturnsTracker()

  events:
    'click .addReturnDetail': (event, template) -> ReturnDetail.addReturnDetail(Session.get('currentSale')._id)
    'click .finishReturn'   : (event, template) -> Return.findOne(Session.get('currentReturn')._id).finishReturn() if Session.get('currentReturn')
    'click .editReturn'     : (event, template) -> Return.findOne(Session.get('currentReturn')._id).editReturn() if Session.get('currentReturn')
    'click .submitReturn'   : (event, template) -> Return.findOne(Session.get('currentReturn')._id).submitReturn() if Session.get('currentReturn')


  returnDetailOptions:
    itemTemplate: 'returnProductThumbnail'
    reactiveSourceGetter: -> Session.get('currentReturnDetails')
    wrapperClasses: 'detail-grid row'

  saleSelectOptions:
    query: (query) -> query.callback
      results: _.filter Session.get('availableSales'), (item) ->
        unsignedTerm = Sky.helpers.removeVnSigns query.term
        unsignedName = Sky.helpers.removeVnSigns item.orderCode
        unsignedName.indexOf(unsignedTerm) > -1
      text: 'orderCode'
    initSelection: (element, callback) -> callback(Session.get('currentSale') ? 'skyReset')
    formatSelection: formatSaleReturnSearch
    formatResult: formatSaleReturnSearch
    id: '_id'
    placeholder: 'CHỌN PHIẾU BÁN HÀNG'
#    minimumResultsForSearch: -1
    changeAction: (e) ->
      Schema.userProfiles.update(Session.get('currentProfile')._id, {$set: {currentSale: e.added._id}})
      sale = Schema.sales.findOne(e.added._id)
      if !sale.currentProductDetail
        saleDetail = Schema.saleDetails.findOne({sale: e.added._id})
        Schema.sales.update(e.added._id, $set:{currentProductDetail: saleDetail._id, currentQuality: 1})
        sale.currentProductDetail = saleDetail._id
        sale.currentQuality       = 1
      Session.set 'currentSale', sale
    reactiveValueGetter: -> Session.get('currentSale') ? 'skyReset'

  returnProductSelectOptions:
    query: (query) -> query.callback
      results: Session.get('currentSaleProductDetails')
    initSelection: (element, callback) -> callback(Schema.saleDetails.findOne(Session.get('currentSale')?.currentProductDetail))
    formatSelection: formatReturnProductSearch
    formatResult: formatReturnProductSearch
    placeholder: 'CHỌN SẢN PHẨM'
#    minimumResultsForSearch: -1
    hotkey: 'return'
    changeAction: (e) ->
      Schema.sales.update(Session.get('currentSale')._id, {$set: {
          currentProductDetail: e.added._id
          currentQuality: 1
        }})
    reactiveValueGetter: -> Session.get('currentSale')?.currentProductDetail

  returnQualityOptions:
    reactiveSetter: (val) ->
      Schema.sales.update(Session.get('currentSale')._id, {$set: {currentQuality: val}})
    reactiveValue: -> Session.get('currentSale')?.currentQuality ? 0
    reactiveMax: -> Session.get('currentMaxQualityReturn') ? 0
    reactiveMin: -> if Session.get('currentMaxQualityReturn') > 0 then 1 else 0
    reactiveStep: -> 1

  discountCashOptions:
    reactiveSetter: (val)->
      option = {discountCash : val}
      if val > 0 then option.discountPercent = val/(Session.get('currentReturn').totalPrice)*100
      else option.discountPercent = 0

      option.finallyPrice = Session.get('currentReturn').totalPrice - option.discountCash
      Schema.returns.update(Session.get('currentReturn')._id, {$set: option}) if Session.get('currentReturn')
    reactiveValue: -> Session.get('currentReturn')?.discountCash ? 0
    reactiveMax: ->  Session.get('currentReturn')?.totalPrice ? 0
    reactiveMin: -> 0
    reactiveStep: -> 1000
    others:
      forcestepdivisibility: 'none'

  discountPercentOptions:
    reactiveSetter: (val) ->
      option = {discountPercent : val}
      if val > 0 then option.discountCash = Math.round((Session.get('currentReturn').totalPrice)/100*val)
      else option.discountCash = 0

      option.finallyPrice = Session.get('currentReturn').totalPrice - option.discountCash
      Schema.returns.update(Session.get('currentReturn')._id, {$set: option}) if Session.get('currentReturn')
    reactiveValue: -> Math.round(Session.get('currentReturn')?.discountPercent) ? 0
    reactiveMax: -> 100
    reactiveMin: -> 0
    reactiveStep: -> 1


