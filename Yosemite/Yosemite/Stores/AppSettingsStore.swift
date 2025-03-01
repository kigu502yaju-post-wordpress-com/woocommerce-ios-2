import Storage
import Networking

// MARK: - AppSettingsStore
//
public class AppSettingsStore: Store {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    private let generalAppSettings: GeneralAppSettingsStorage

    /// Designated initaliser
    ///
    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                fileStorage: FileStorage,
                generalAppSettings: GeneralAppSettingsStorage) {
        self.fileStorage = fileStorage
        self.generalAppSettings = generalAppSettings
        super.init(dispatcher: dispatcher,
                   storageManager: storageManager,
                   network: NullNetwork())
    }

    /// URL to the plist file that we use to store the user selected
    /// shipment tracing provider. Not declared as `private` so it can
    /// be overridden in tests
    ///
    lazy var selectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.shipmentProvidersFileName)
    }()

    /// URL to the plist file that we use to store the user selected
    /// custom shipment tracing provider. Not declared as `private` so it can
    /// be overridden in tests
    ///
    lazy var customSelectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.customShipmentProvidersFileName)
    }()

    private lazy var generalStoreSettingsFileURL: URL! = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.generalStoreSettingsFileName)
    }()

    /// URL to the plist file that we use to determine the settings applied in Orders
    ///
    private lazy var ordersSettingsURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.ordersSettings)
    }()

    /// URL to the plist file that we use to determine the settings applied in Products
    ///
    private lazy var productsSettingsURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.productsSettings)
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AppSettingsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AppSettingsAction else {
            assertionFailure("ShipmentStore received an unsupported action")
            return
        }

        switch action {
        case .addTrackingProvider(let siteID, let providerName, let onCompletion):
            addTrackingProvider(siteID: siteID,
                                providerName: providerName,
                                onCompletion: onCompletion)
        case .loadTrackingProvider(let siteID, let onCompletion):
            loadTrackingProvider(siteID: siteID,
                                 onCompletion: onCompletion)
        case .addCustomTrackingProvider(let siteID,
                                        let providerName,
                                        let providerURL,
                                        let onCompletion):
            addCustomTrackingProvider(siteID: siteID,
                                      providerName: providerName,
                                      providerURL: providerURL,
                                      onCompletion: onCompletion)
        case .loadCustomTrackingProvider(let siteID,
                                         let onCompletion):
            loadCustomTrackingProvider(siteID: siteID,
                                       onCompletion: onCompletion)
        case .resetStoredProviders(let onCompletion):
            resetStoredProviders(onCompletion: onCompletion)
        case .setInstallationDateIfNecessary(let date, let onCompletion):
            setInstallationDateIfNecessary(date: date, onCompletion: onCompletion)
        case .updateFeedbackStatus(let type, let status, let onCompletion):
            updateFeedbackStatus(type: type, status: status, onCompletion: onCompletion)
        case .loadFeedbackVisibility(let type, let onCompletion):
            loadFeedbackVisibility(type: type, onCompletion: onCompletion)
        case .loadOrdersSettings(let siteID, let onCompletion):
            loadOrdersSettings(siteID: siteID, onCompletion: onCompletion)
        case .upsertOrdersSettings(let siteID,
                                   let orderStatusesFilter,
                                   let dateRangeFilter,
                                   let onCompletion):
            upsertOrdersSettings(siteID: siteID,
                                 orderStatusesFilter: orderStatusesFilter,
                                 dateRangeFilter: dateRangeFilter,
                                 onCompletion: onCompletion)
        case .resetOrdersSettings:
            resetOrdersSettings()
        case .loadProductsSettings(let siteID, let onCompletion):
            loadProductsSettings(siteID: siteID, onCompletion: onCompletion)
        case .upsertProductsSettings(let siteID,
                                     let sort,
                                     let stockStatusFilter,
                                     let productStatusFilter,
                                     let productTypeFilter,
                                     let productCategoryFilter,
                                     let onCompletion):
            upsertProductsSettings(siteID: siteID,
                                   sort: sort,
                                   stockStatusFilter: stockStatusFilter,
                                   productStatusFilter: productStatusFilter,
                                   productTypeFilter: productTypeFilter,
                                   productCategoryFilter: productCategoryFilter,
                                   onCompletion: onCompletion)
        case .resetProductsSettings:
            resetProductsSettings()
        case .setOrderAddOnsFeatureSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setOrderAddOnsFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadOrderAddOnsSwitchState(onCompletion: let onCompletion):
            loadOrderAddOnsSwitchState(onCompletion: onCompletion)
        case .rememberCardReader(cardReaderID: let cardReaderID, onCompletion: let onCompletion):
            rememberCardReader(cardReaderID: cardReaderID, onCompletion: onCompletion)
        case .forgetCardReader(onCompletion: let onCompletion):
            forgetCardReader(onCompletion: onCompletion)
        case .loadCardReader(onCompletion: let onCompletion):
            loadCardReader(onCompletion: onCompletion)
        case .loadEligibilityErrorInfo(onCompletion: let onCompletion):
            loadEligibilityErrorInfo(onCompletion: onCompletion)
        case .setEligibilityErrorInfo(errorInfo: let errorInfo, onCompletion: let onCompletion):
            setEligibilityErrorInfo(errorInfo: errorInfo, onCompletion: onCompletion)
        case .resetEligibilityErrorInfo:
            setEligibilityErrorInfo(errorInfo: nil)
        case .setJetpackBenefitsBannerLastDismissedTime(time: let time):
            setJetpackBenefitsBannerLastDismissedTime(time: time)
        case .loadJetpackBenefitsBannerVisibility(currentTime: let currentTime, calendar: let calendar, onCompletion: let onCompletion):
            loadJetpackBenefitsBannerVisibility(currentTime: currentTime, calendar: calendar, onCompletion: onCompletion)
        case .setTelemetryAvailability(siteID: let siteID, isAvailable: let isAvailable):
            setTelemetryAvailability(siteID: siteID, isAvailable: isAvailable)
        case .setTelemetryLastReportedTime(siteID: let siteID, time: let time):
            setTelemetryLastReportedTime(siteID: siteID, time: time)
        case .getTelemetryInfo(siteID: let siteID, onCompletion: let onCompletion):
            getTelemetryInfo(siteID: siteID, onCompletion: onCompletion)
        case let .setSimplePaymentsTaxesToggleState(siteID, isOn, onCompletion):
            setSimplePaymentsTaxesToggleState(siteID: siteID, isOn: isOn, onCompletion: onCompletion)
        case let .getSimplePaymentsTaxesToggleState(siteID, onCompletion):
            getSimplePaymentsTaxesToggleState(siteID: siteID, onCompletion: onCompletion)
        case let .setPreferredInPersonPaymentGateway(siteID: siteID, gateway: gateway):
            setPreferredInPersonPaymentGateway(siteID: siteID, gateway: gateway)
        case let .getPreferredInPersonPaymentGateway(siteID: siteID, onCompletion: onCompletion):
            getPreferredInPersonPaymentGateway(siteID: siteID, onCompletion: onCompletion)
        case let .forgetPreferredInPersonPaymentGateway(siteID: siteID):
            forgetPreferredInPersonPaymentGateway(siteID: siteID)
        case .resetGeneralStoreSettings:
            resetGeneralStoreSettings()
        case .setProductSKUInputScannerFeatureSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setProductSKUInputScannerFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadProductSKUInputScannerFeatureSwitchState(onCompletion: let onCompletion):
            loadProductSKUInputScannerFeatureSwitchState(onCompletion: onCompletion)
        case .setCouponManagementFeatureSwitchState(let isEnabled, let onCompletion):
            setCouponManagementFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadCouponManagementFeatureSwitchState(let onCompletion):
            loadCouponManagementFeatureSwitchState(onCompletion: onCompletion)
        case .loadProductMultiSelectionFeatureSwitchState(let onCompletion):
            loadProductMultiSelectionFeatureSwitchState(onCompletion: onCompletion)
        case .setProductMultiSelectionFeatureSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setProductMultiSelectionFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .setFeatureAnnouncementDismissed(campaign: let campaign, remindAfterDays: let remindAfterDays, onCompletion: let completion):
            setFeatureAnnouncementDismissed(campaign: campaign, remindAfterDays: remindAfterDays, onCompletion: completion)
        case .getFeatureAnnouncementVisibility(campaign: let campaign, onCompletion: let completion):
            getFeatureAnnouncementVisibility(campaign: campaign, onCompletion: completion)
        case .setSkippedCashOnDeliveryOnboardingStep(siteID: let siteID):
            setSkippedCashOnDeliveryOnboardingStep(siteID: siteID)
        case .getSkippedCashOnDeliveryOnboardingStep(siteID: let siteID, onCompletion: let completion):
            getSkippedCashOnDeliveryOnboardingStep(siteID: siteID, onCompletion: completion)
        case .setLastSelectedStatsTimeRange(let siteID, let timeRange):
            setLastSelectedStatsTimeRange(siteID: siteID, timeRange: timeRange)
        case .loadLastSelectedStatsTimeRange(let siteID, let onCompletion):
            loadLastSelectedStatsTimeRange(siteID: siteID, onCompletion: onCompletion)
        case .loadSiteHasAtLeastOneIPPTransactionFinished(let siteID, let onCompletion):
            loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID, onCompletion: onCompletion)
        case .markSiteHasAtLeastOneIPPTransactionFinished(let siteID):
            markSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID)

        }
    }
}

// MARK: - General App Settings

private extension AppSettingsStore {
    /// Save the `date` in `GeneralAppSettings` but only if the `date` is older than the existing
    /// `GeneralAppSettings.installationDate`.
    ///
    /// - Parameter onCompletion: The `Result`'s success value will be `true` if the installation
    ///                           date was changed and `false` if not.
    ///
    func setInstallationDateIfNecessary(date: Date, onCompletion: ((Result<Bool, Error>) -> Void)) {
        do {
            if let installationDate = generalAppSettings.value(for: \.installationDate),
               date > installationDate {
                return onCompletion(.success(false))
            }

            try generalAppSettings.setValue(date, for: \.installationDate)

            onCompletion(.success(true))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Updates the feedback store  in `GeneralAppSettings` with the given `type` and `status`.
    ///
    func updateFeedbackStatus(type: FeedbackType, status: FeedbackSettings.Status, onCompletion: ((Result<Void, Error>) -> Void)) {
        do {
            let settings = generalAppSettings.settings
            let newFeedback = FeedbackSettings(name: type, status: status)
            let settingsToSave = settings.replacing(feedback: newFeedback)
            try generalAppSettings.saveSettings(settingsToSave)

            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    func loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void) {
        let settings = generalAppSettings.settings
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: type)

        onCompletion(Result {
            try useCase.shouldBeVisible()
        })
    }

    /// Sets the provided Order Add-Ons beta feature switch state into `GeneralAppSettings`
    ///
    func setOrderAddOnsFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalAppSettings.setValue(isEnabled, for: \.isViewAddOnsSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }

    }

    /// Loads the current Order Add-Ons beta feature switch state from `GeneralAppSettings`
    ///
    func loadOrderAddOnsSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(generalAppSettings.value(for: \.isViewAddOnsSwitchEnabled)))
    }

    /// Sets the state for the Product SKU Input Scanner beta feature switch into `GeneralAppSettings`.
    ///
    func setProductSKUInputScannerFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalAppSettings.setValue(isEnabled, for: \.isProductSKUInputScannerSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the most recent state for the Product SKU Input Scanner beta feature switch from `GeneralAppSettings`.
    ///
    func loadProductSKUInputScannerFeatureSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(generalAppSettings.value(for: \.isProductSKUInputScannerSwitchEnabled)))
    }

    /// Sets the state for the Coupon Mangagement beta feature switch into `GeneralAppSettings`.
    ///
    func setCouponManagementFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalAppSettings.setValue(isEnabled, for: \.isCouponManagementSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the most recent state for the Coupon Management beta feature switch from `GeneralAppSettings`.
    ///
    func loadCouponManagementFeatureSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(generalAppSettings.value(for: \.isCouponManagementSwitchEnabled)))
    }

    /// Loads the most recent state for the Product Multi-Selection experimental feature switch from `GeneralAppSettings`.
    ///
    func loadProductMultiSelectionFeatureSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(generalAppSettings.value(for: \.isProductMultiSelectionSwitchEnabled)))
    }

    /// Sets the state for the Product Multi-Selection experimental feature switch from `GeneralAppSettings`
    ///
    func setProductMultiSelectionFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalAppSettings.setValue(isEnabled, for: \.isProductMultiSelectionSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the last persisted eligibility error information from `GeneralAppSettings`
    ///
    func loadEligibilityErrorInfo(onCompletion: (Result<EligibilityErrorInfo, Error>) -> Void) {
        guard let errorInfo = generalAppSettings.value(for: \.lastEligibilityErrorInfo) else {
            return onCompletion(.failure(AppSettingsStoreErrors.noEligibilityErrorInfo))
        }

        onCompletion(.success(errorInfo))
    }

    func setEligibilityErrorInfo(errorInfo: EligibilityErrorInfo?, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            try generalAppSettings.setValue(errorInfo, for: \.lastEligibilityErrorInfo)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
        }
    }

    // Visibility of Jetpack benefits banner in the Dashboard

    func setJetpackBenefitsBannerLastDismissedTime(time: Date, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            try generalAppSettings.setValue(time, for: \.lastJetpackBenefitsBannerDismissedTime)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
        }
    }

    func loadJetpackBenefitsBannerVisibility(currentTime: Date, calendar: Calendar, onCompletion: (Bool) -> Void) {
        guard let lastDismissedTime = generalAppSettings.value(for: \.lastJetpackBenefitsBannerDismissedTime) else {
            // If the banner has not been dismissed before, the banner is default to be visible.
            return onCompletion(true)
        }

        guard let numberOfDaysSinceLastDismissal = calendar.dateComponents([.day], from: lastDismissedTime, to: currentTime).day else {
            return onCompletion(true)
        }
        onCompletion(numberOfDaysSinceLastDismissal >= 5)
    }
}

// MARK: - Card Reader Actions
//
private extension AppSettingsStore {
    /// Remember the given card reader (to support automatic reconnection)
    /// where `cardReaderID` is a String e.g. "CHB204909005931"
    ///
    func rememberCardReader(cardReaderID: String, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            guard !generalAppSettings.value(for: \.knownCardReaders).contains(cardReaderID) else {
                return onCompletion(.success(()))
            }

            /// NOTE: We now only persist one card reader maximum, although for backwards compatibility
            /// we still do so as an array
            let knownCardReadersToSave = [cardReaderID]
            try generalAppSettings.setValue(knownCardReadersToSave, for: \.knownCardReaders)

            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Forget any remembered card reader (i.e. automatic reconnection is no longer desired)
    ///
    func forgetCardReader(onCompletion: (Result<Void, Error>) -> Void) {
        do {
            /// NOTE: Since we now only persist one card reader maximum, we no longer use
            /// the argument and always save an empty array to the settings.
            try generalAppSettings.setValue([], for: \.knownCardReaders)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the most recently remembered card reader, if any (i.e. to reconnect to automatically)
    /// NOTE: We now only persist one card reader maximum.
    /// E.g.  "CHB204909005931"
    ///
    func loadCardReader(onCompletion: (Result<String?, Error>) -> Void) {
        /// NOTE: We now only persist one card reader maximum, although for backwards compatibility
        /// we still do so as an array. We use last here so that we can get the most recently remembered
        /// reader from appSettings if populated by an older version
        guard let knownReader = generalAppSettings.value(for: \.knownCardReaders).last else {
            onCompletion(.success(nil))
            return
        }

        onCompletion(.success(knownReader))
    }
}

// MARK: - Shipment tracking providers!
//
private extension AppSettingsStore {
    func addTrackingProvider(siteID: Int64,
                             providerName: String,
                             onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    fileURL: selectedProvidersURL,
                    onCompletion: onCompletion)

    }

    func addCustomTrackingProvider(siteID: Int64,
                                   providerName: String,
                                   providerURL: String?,
                                   onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    providerURL: providerURL,
                    fileURL: customSelectedProvidersURL,
                    onCompletion: onCompletion)
    }

    func addProvider(siteID: Int64,
                     providerName: String,
                     providerURL: String? = nil,
                     fileURL: URL,
                     onCompletion: (Error?) -> Void) {
        guard let settings: [PreselectedProvider] = try? fileStorage.data(for: fileURL) else {
            insertNewProvider(siteID: siteID,
                              providerName: providerName,
                              providerURL: providerURL,
                              toFileURL: fileURL,
                              onCompletion: onCompletion)
            return
        }
        saveTrackingProvider(siteID: siteID,
                               providerName: providerName,
                               preselectedData: settings,
                               toFileURL: fileURL,
                               onCompletion: onCompletion)
    }

    func loadTrackingProvider(siteID: Int64,
                              onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void) {
        guard let allSavedProviders: [PreselectedProvider] = try? fileStorage.data(for: selectedProvidersURL) else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, nil, error)
            return
        }

        let providerName = allSavedProviders.filter {
            $0.siteID == siteID
        }.first?.providerName

        guard let name = providerName else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, nil, error)
            return
        }

        let provider = storageManager
            .viewStorage
            .loadShipmentTrackingProvider(siteID: siteID,
                                          name: name)

        onCompletion(provider?.toReadOnly(), provider?.group?.toReadOnly(), nil)
    }

    func loadCustomTrackingProvider(siteID: Int64,
                                    onCompletion: (ShipmentTrackingProvider?, Error?) -> Void) {
        guard let allSavedProviders: [PreselectedProvider] = try? fileStorage.data(for: customSelectedProvidersURL) else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, error)
            return
        }

        let providerName = allSavedProviders.filter {
            $0.siteID == siteID
        }.first?.providerName

        let providerURL = allSavedProviders.filter {
            $0.siteID == siteID
        }.first?.providerURL

        guard let name = providerName else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, error)
            return
        }

        let customProvider = ShipmentTrackingProvider(siteID: siteID,
                                                      name: name,
                                                      url: providerURL ?? "")
        onCompletion(customProvider, nil)
    }

    func saveTrackingProvider(siteID: Int64,
                                providerName: String,
                                providerURL: String? = nil,
                                preselectedData: [PreselectedProvider],
                                toFileURL: URL,
                                onCompletion: (Error?) -> Void) {
        let newPreselectedProvider = PreselectedProvider(siteID: siteID,
                                                         providerName: providerName,
                                                         providerURL: providerURL)
        let dataToSave = [newPreselectedProvider]

        do {
            try fileStorage.write(dataToSave, to: toFileURL)
            onCompletion(nil)
        } catch {
            onCompletion(error)
        }
    }

    func insertNewProvider(siteID: Int64,
                           providerName: String,
                           providerURL: String? = nil,
                           toFileURL: URL,
                           onCompletion: (Error?) -> Void) {
        let preselectedProvider = PreselectedProvider(siteID: siteID,
                                                      providerName: providerName,
                                                      providerURL: providerURL)

        do {
            try fileStorage.write([preselectedProvider], to: toFileURL)
            onCompletion(nil)
        } catch {
            onCompletion(error)
        }
    }

    func resetStoredProviders(onCompletion: ((Error?) -> Void)? = nil) {
        do {
            try fileStorage.deleteFile(at: selectedProvidersURL)
            try fileStorage.deleteFile(at: customSelectedProvidersURL)
            onCompletion?(nil)
        } catch {
            let error = AppSettingsStoreErrors.deletePreselectedProvider
            onCompletion?(error)
        }
    }
}

// MARK: - Orders Settings
//
private extension AppSettingsStore {
    func loadOrdersSettings(siteID: Int64, onCompletion: (Result<StoredOrderSettings.Setting, Error>) -> Void) {
        guard let allSavedSettings: StoredOrderSettings = try? fileStorage.data(for: ordersSettingsURL),
                let settingsUnwrapped = allSavedSettings.settings[siteID] else {
            let error = AppSettingsStoreErrors.noOrdersSettings
            onCompletion(.failure(error))
            return
        }

        onCompletion(.success(settingsUnwrapped))
    }

    func upsertOrdersSettings(siteID: Int64,
                              orderStatusesFilter: [OrderStatusEnum]?,
                              dateRangeFilter: OrderDateRangeFilter?,
                              onCompletion: (Error?) -> Void) {
        var existingSettings: [Int64: StoredOrderSettings.Setting] = [:]
        if let storedSettings: StoredOrderSettings = try? fileStorage.data(for: ordersSettingsURL) {
            existingSettings = storedSettings.settings
        }

        let newSettings = StoredOrderSettings.Setting(siteID: siteID,
                                                      orderStatusesFilter: orderStatusesFilter,
                                                      dateRangeFilter: dateRangeFilter)
        existingSettings[siteID] = newSettings

        let newStoredOrderSettings = StoredOrderSettings(settings: existingSettings)
        do {
            try fileStorage.write(newStoredOrderSettings, to: ordersSettingsURL)
            onCompletion(nil)
        } catch {
            onCompletion(AppSettingsStoreErrors.writeOrdersSettings)
        }
    }

    func resetOrdersSettings() {
        do {
            try fileStorage.deleteFile(at: ordersSettingsURL)
        } catch {
            DDLogError("⛔️ Deleting the orders settings files failed. Error: \(error)")
        }
    }
}

// MARK: - Products Settings
//
private extension AppSettingsStore {
    func loadProductsSettings(siteID: Int64, onCompletion: (Result<StoredProductSettings.Setting, Error>) -> Void) {
        guard let allSavedSettings: StoredProductSettings = try? fileStorage.data(for: productsSettingsURL) else {
            let error = AppSettingsStoreErrors.noProductsSettings
            onCompletion(.failure(error))
            return
        }

        guard let settingsUnwrapped = allSavedSettings.settings[siteID] else {
            let error = AppSettingsStoreErrors.noProductsSettings
            onCompletion(.failure(error))
            return
        }

        onCompletion(.success(settingsUnwrapped))
    }

    func upsertProductsSettings(siteID: Int64,
                                sort: String? = nil,
                                stockStatusFilter: ProductStockStatus? = nil,
                                productStatusFilter: ProductStatus? = nil,
                                productTypeFilter: ProductType? = nil,
                                productCategoryFilter: ProductCategory? = nil,
                                onCompletion: (Error?) -> Void) {
        var existingSettings: [Int64: StoredProductSettings.Setting] = [:]
        if let storedSettings: StoredProductSettings = try? fileStorage.data(for: productsSettingsURL) {
            existingSettings = storedSettings.settings
        }

        let newSetting = StoredProductSettings.Setting(siteID: siteID,
                                                       sort: sort,
                                                       stockStatusFilter: stockStatusFilter,
                                                       productStatusFilter: productStatusFilter,
                                                       productTypeFilter: productTypeFilter,
                                                       productCategoryFilter: productCategoryFilter)
        existingSettings[siteID] = newSetting

        let newStoredProductSettings = StoredProductSettings(settings: existingSettings)
        do {
            try fileStorage.write(newStoredProductSettings, to: productsSettingsURL)
            onCompletion(nil)
        } catch {
            onCompletion(AppSettingsStoreErrors.writeProductsSettings)
        }
    }

    func resetProductsSettings() {
        do {
            try fileStorage.deleteFile(at: productsSettingsURL)
        } catch {
            DDLogError("⛔️ Deleting the product settings files failed. Error: \(error)")
        }
    }
}

// MARK: - Store settings
//
private extension AppSettingsStore {

    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        guard let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL),
              let storeSettings = existingData.storeSettingsBySite[siteID] else {
            return GeneralStoreSettings()
        }

        return storeSettings
    }

    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        var storeSettingsBySite: [Int64: GeneralStoreSettings] = [:]
        if let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL) {
            storeSettingsBySite = existingData.storeSettingsBySite
        }

        storeSettingsBySite[siteID] = settings

        do {
            try fileStorage.write(GeneralStoreSettingsBySite(storeSettingsBySite: storeSettingsBySite), to: generalStoreSettingsFileURL)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
            DDLogError("⛔️ Saving store settings to file failed. Error: \(error)")
        }
    }

    // Telemetry data

    func setTelemetryAvailability(siteID: Int64, isAvailable: Bool, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(isTelemetryAvailable: isAvailable)
        setStoreSettings(settings: updatedSettings, for: siteID, onCompletion: onCompletion)
    }

    func setTelemetryLastReportedTime(siteID: Int64, time: Date, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(telemetryLastReportedTime: time)
        setStoreSettings(settings: updatedSettings, for: siteID, onCompletion: onCompletion)
    }

    func getTelemetryInfo(siteID: Int64, onCompletion: (Bool, Date?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.isTelemetryAvailable, storeSettings.telemetryLastReportedTime)
    }

    func resetGeneralStoreSettings() {
        do {
            try fileStorage.deleteFile(at: generalStoreSettingsFileURL)
        } catch {
            DDLogError("⛔️ Deleting store settings file failed. Error: \(error)")
        }
    }

    // Simple Payments data

    /// Sets the last state of the simple payments taxes toggle for a provided store.
    ///
    func setSimplePaymentsTaxesToggleState(siteID: Int64, isOn: Bool, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(areSimplePaymentTaxesEnabled: isOn)
        setStoreSettings(settings: newSettings, for: siteID, onCompletion: onCompletion)
    }

    /// Get the last state of the simple payments taxes toggle for a provided store.
    ///
    func getSimplePaymentsTaxesToggleState(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(.success(storeSettings.areSimplePaymentTaxesEnabled))
    }

    /// Sets the preferred payment gateway for In-Person Payments
    ///
    func setPreferredInPersonPaymentGateway(siteID: Int64, gateway: String) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(preferredInPersonPaymentGateway: gateway)
        setStoreSettings(settings: newSettings, for: siteID, onCompletion: nil)
    }

    /// Gets the preferred payment gateway for In-Person Payments
    ///
    func getPreferredInPersonPaymentGateway(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.preferredInPersonPaymentGateway)
    }

    /// Forgets the preferred payment gateway for In-Person Payments
    ///
    func forgetPreferredInPersonPaymentGateway(siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(preferredInPersonPaymentGateway: .some(nil))
        setStoreSettings(settings: newSettings, for: siteID, onCompletion: nil)
    }

    /// Marks the Enable Cash on Delivery In-Person Payments Onboarding step as skipped
    ///
    func setSkippedCashOnDeliveryOnboardingStep(siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(skippedCashOnDeliveryOnboardingStep: true)
        setStoreSettings(settings: newSettings, for: siteID)
    }

    /// Gets whether the Enable Cash on Delivery In-Person Payments Onboarding step has been skipped
    ///
    func getSkippedCashOnDeliveryOnboardingStep(siteID: Int64, onCompletion: (Bool) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.skippedCashOnDeliveryOnboardingStep)
    }

}


// MARK: - Feature Announcement Card Visibility

extension AppSettingsStore {

    func setFeatureAnnouncementDismissed(
        campaign: FeatureAnnouncementCampaign,
        remindAfterDays: Int?,
        onCompletion: ((Result<Bool, Error>) -> ())?) {
            do {
                guard let remindAfterDays else {
                    return
                }
                let remindAfter = Date().addingDays(remindAfterDays)
                let newSettings = FeatureAnnouncementCampaignSettings(dismissedDate: Date(), remindAfter: remindAfter)

                let settings = generalAppSettings.settings
                let settingsToSave = settings.replacing(featureAnnouncementSettings: newSettings, for: campaign)
                try generalAppSettings.saveSettings(settingsToSave)

                onCompletion?(.success(true))
            } catch {
                onCompletion?(.failure(error))
            }
        }

    func getFeatureAnnouncementVisibility(campaign: FeatureAnnouncementCampaign, onCompletion: (Result<Bool, Error>) -> ()) {
        guard let campaignSettings = generalAppSettings.value(for: \.featureAnnouncementCampaignSettings)[campaign] else {
            return onCompletion(.success(true))
        }

        if let remindAfter = campaignSettings.remindAfter {
            let remindAfterHasPassed = remindAfter < Date()
            onCompletion(.success(remindAfterHasPassed))
        } else {
            let neverDismissed = campaignSettings.dismissedDate == nil
            onCompletion(.success(neverDismissed))
        }
    }

    func loadSiteHasAtLeastOneIPPTransactionFinished(siteID: Int64, onCompletion: (Bool) -> Void) {
        onCompletion(generalAppSettings.value(for: \.sitesWithAtLeastOneIPPTransactionFinished).contains(siteID))
    }

    func markSiteHasAtLeastOneIPPTransactionFinished(siteID: Int64) {
        var updatingSet = generalAppSettings.settings.sitesWithAtLeastOneIPPTransactionFinished
        updatingSet.insert(siteID)

        try? generalAppSettings.setValue(updatingSet, for: \.sitesWithAtLeastOneIPPTransactionFinished)
    }
}

private extension AppSettingsStore {
    func setLastSelectedStatsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedStatsTimeRange: timeRange.rawValue)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedStatsTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let timeRangeRawValue = storeSettings.lastSelectedStatsTimeRange
        let timeRange = StatsTimeRangeV4(rawValue: timeRangeRawValue)
        onCompletion(timeRange)
    }
}

// MARK: - Errors

/// Errors
///
enum AppSettingsStoreErrors: Error {
    case parsePreselectedProvider
    case writePreselectedProvider
    case readPreselectedProvider
    case deletePreselectedProvider
    case readPListFromFileStorage
    case writePListToFileStorage
    case noOrdersSettings
    case noProductsSettings
    case writeOrdersSettings
    case writeProductsSettings
    case noEligibilityErrorInfo
}


// MARK: - Constants

/// Constants
///
private enum Constants {

    // MARK: File Names
    static let shipmentProvidersFileName = "shipment-providers.plist"
    static let customShipmentProvidersFileName = "custom-shipment-providers.plist"
    static let generalStoreSettingsFileName = "general-store-settings.plist"
    static let ordersSettings = "orders-settings.plist"
    static let productsSettings = "products-settings.plist"
}
