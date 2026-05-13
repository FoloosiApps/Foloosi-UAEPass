package com.foloosi.foloosi_pass

import ae.sdg.libraryuaepass.business.Environment
import ae.sdg.libraryuaepass.business.Language
import ae.sdg.libraryuaepass.business.authentication.model.UAEPassAccessTokenRequestModel
import ae.sdg.libraryuaepass.business.documentsigning.model.DocumentSigningRequestParams
import ae.sdg.libraryuaepass.business.documentsigning.model.UAEPassDocumentDownloadRequestModel
import ae.sdg.libraryuaepass.business.documentsigning.model.UAEPassDocumentSigningRequestModel
import ae.sdg.libraryuaepass.business.profile.model.UAEPassProfileRequestModel
import ae.sdg.libraryuaepass.utils.Utils.generateRandomString
import android.content.Context
import android.content.pm.PackageManager
import java.io.File

object UAEPassRequestModels {

    // ------------------------------------------------------------------
    // 1) OVERRIDE VARIABLES
    //    These are set at runtime from MainActivity (or anywhere else)
    // ------------------------------------------------------------------
    var overrideEnvironment: Environment? = null       // e.g., Environment.QA
    var overrideLanguage: Language? = null             // e.g., Language.AR
    var overrideAuthMethod: String? = null            // "PIN" or "FACE"
    private var overrideClientId: String = ""         // Override for client ID
    private var overrideRedirectUrl: String = ""      // Override for redirect URL

    // Add to override variables section
    var isForceWebView: Boolean = false  // Control web vs app behavior

    // ------------------------------------------------------------------
    // 2) FALLBACK CONSTANTS FROM BuildConfig (Default if no override)
    // ------------------------------------------------------------------
    private const val UAE_PASS_CLIENT_ID = "foloosi_mob_stage"
    private const val REDIRECT_URL = "https://promo.foloosi.com/auth/callback/mobile"

    private const val DOCUMENT_SIGNING_SCOPE = "urn:safelayer:eidas:sign:process:document"
    private const val RESPONSE_TYPE = "code"
    private const val SCOPE = "urn:uae:digitalid:profile"

    private const val ACR_VALUES_MOBILE = "urn:digitalid:authentication:flow:mobileondevice"
    private const val ACR_VALUES_WEB = "urn:safelayer:tws:policies:authentication:level:low"

    // UAE Pass app package IDs by environment
    private const val UAE_PASS_PACKAGE_ID = "ae.uaepass.mainapp"
    private const val UAE_PASS_DEV_PACKAGE_ID = "ae.uaepass.mainapp.dev"
    private const val UAE_PASS_QA_PACKAGE_ID = "ae.uaepass.mainapp.qa"
    private const val UAE_PASS_STG_PACKAGE_ID = "ae.uaepass.mainapp.stg"

    // Scheme & hosts from your BuildConfig
    private const val SCHEME = "foloosi"
    private const val FAILURE_HOST = "failure"
    private const val SUCCESS_HOST = "success"

    // Random state for OAuth flow
    private val STATE = generateRandomString(24)

    // ------------------------------------------------------------------
    // 3) Credential Override Functions
    // ------------------------------------------------------------------
    fun updateCredentials(clientId: String, redirectUrl: String) {
        overrideClientId = clientId
        overrideRedirectUrl = redirectUrl
    }

    fun updateClientID(clientId: String) {
        overrideClientId = clientId
    }

    private fun getClientId(): String =
        overrideClientId.takeIf { it.isNotEmpty() } ?: UAE_PASS_CLIENT_ID

    private fun getRedirectUrl(): String =
        overrideRedirectUrl.takeIf { it.isNotEmpty() } ?: REDIRECT_URL

    // ------------------------------------------------------------------
    // 4) Environment Management
    // ------------------------------------------------------------------
    val UAE_PASS_ENVIRONMENT: Environment
        get() = overrideEnvironment ?: EnvironmentManager.getCurrentEnvironment()

    object EnvironmentManager {
        private var selectedEnvironment: Environment = Environment.QA // Default to QA

        fun getCurrentEnvironment(): Environment {
            return selectedEnvironment
        }

        fun setEnvironment(environment: Environment) {
            selectedEnvironment = environment
        }
    }

    // ------------------------------------------------------------------
    // 5) Helper Functions
    // ------------------------------------------------------------------

    /**
     * This function determines which environment to use by default,
     * based on which UAE Pass app packages are installed.
     *   1) If **none** are installed, returns [Environment.PRODUCTION]
     *   2) If **more than 1** is installed, returns [Environment.QA]
     *   3) If exactly 1 is installed, returns that environment
     */
    fun determineDefaultEnvironment(pm: PackageManager): Environment {
        val installedEnvironments = mutableListOf<Environment>()
        if (isPackageInstalled(
                Environment.PRODUCTION,
                pm
            )
        ) installedEnvironments.add(Environment.PRODUCTION)
        if (isPackageInstalled(
                Environment.STAGING,
                pm
            )
        ) installedEnvironments.add(Environment.STAGING)
        if (isPackageInstalled(Environment.QA, pm)) installedEnvironments.add(Environment.QA)
        if (isPackageInstalled(Environment.DEV, pm)) installedEnvironments.add(Environment.DEV)

        return when {
            installedEnvironments.isEmpty() -> Environment.PRODUCTION
            installedEnvironments.size > 1 -> Environment.QA
            else -> installedEnvironments.first() // Exactly one found
        }
    }

    fun isPackageInstalled(env: Environment, pm: PackageManager): Boolean {
        val packageName = when (env) {
            Environment.DEV -> UAE_PASS_DEV_PACKAGE_ID
            Environment.QA -> UAE_PASS_QA_PACKAGE_ID
            Environment.STAGING -> UAE_PASS_STG_PACKAGE_ID
            Environment.PRODUCTION -> UAE_PASS_PACKAGE_ID
        }
        return try {
            pm.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun getCurrentEnvironment(): Environment {
        return overrideEnvironment ?: UAE_PASS_ENVIRONMENT
    }

    private fun getCurrentLanguage(): Language {
        return overrideLanguage ?: Language.EN
    }

    /**
     * Decide the correct `acrValues` based on environment, whether user forced web,
     * or whether face authentication was selected.
     */
    private fun getAcrValue(env: Environment, pm: PackageManager): String {
        val chosenAuth = overrideAuthMethod ?: "PIN"
        return if (isForceWebView) {
            // Always return web value if force web view is enabled
            ACR_VALUES_WEB
        } else if (chosenAuth == "PIN" || chosenAuth == "FACE") {
            // Normal behavior - check if app is installed
            if (isPackageInstalled(env, pm)) ACR_VALUES_MOBILE else ACR_VALUES_WEB
        } else {
            // For FACE always use web
            ACR_VALUES_WEB
        }
    }

    // ------------------------------------------------------------------
    // 6) Request Model Generators
    // ------------------------------------------------------------------
    fun getAuthenticationRequestModel(context: Context): UAEPassAccessTokenRequestModel {
        val env = getCurrentEnvironment()
        val acrValue = getAcrValue(env, context.packageManager)
        val lang = getCurrentLanguage()

        return UAEPassAccessTokenRequestModel(
            environment = env,
            clientId = getClientId(),
            scheme = SCHEME,
            failureHost = FAILURE_HOST,
            successHost = SUCCESS_HOST,
            redirectUrl = getRedirectUrl(),
            scope = DOCUMENT_SIGNING_SCOPE,   // signing scope so the auth code can be exchanged for a signing token
            responseType = RESPONSE_TYPE,
            acrValues = acrValue,
            state = STATE,
            locale = lang
        )
    }

    fun getProfileRequestModel(context: Context): UAEPassProfileRequestModel {
        val env = getCurrentEnvironment()
        val acrValue = getAcrValue(env, context.packageManager)
        val lang = getCurrentLanguage()

        return UAEPassProfileRequestModel(
            environment = env,
            clientId = getClientId(),
            scheme = SCHEME,
            failureHost = FAILURE_HOST,
            successHost = SUCCESS_HOST,
            redirectUrl = getRedirectUrl(),
            scope = SCOPE,
            responseType = RESPONSE_TYPE,
            acrValues = acrValue,
            state = STATE,
            locale = lang
        )
    }

    fun getDocumentRequestModel(
        file: File,
        requestObject: DocumentSigningRequestParams
    ): UAEPassDocumentSigningRequestModel {
        val env = getCurrentEnvironment()
        return UAEPassDocumentSigningRequestModel(
            environment = env,
            clientId = getClientId(),
            scheme = SCHEME,
            failureHost = FAILURE_HOST,
            successHost = SUCCESS_HOST,
            redirectUrl = requestObject.finishCallbackUrl,
            scope = DOCUMENT_SIGNING_SCOPE,
            document = file,
            requestObject = requestObject
        )
    }

    fun getMultipleDocumentSigningRequestModel(
        files: List<File>,
        requestObject: DocumentSigningRequestParams
    ): List<UAEPassDocumentSigningRequestModel> {
        val env = getCurrentEnvironment()

        return files.map { file ->
            UAEPassDocumentSigningRequestModel(
                environment = env,
                clientId = getClientId(),
                scheme = SCHEME,
                failureHost = FAILURE_HOST,
                successHost = SUCCESS_HOST,
                redirectUrl = requestObject.finishCallbackUrl,
                scope = DOCUMENT_SIGNING_SCOPE,
                document = file,
                requestObject = requestObject
            )
        }
    }

    fun getDocumentDownloadRequestModel(
        documentName: String,
        documentURL: String?
    ): UAEPassDocumentDownloadRequestModel {
        val env = getCurrentEnvironment()
        return UAEPassDocumentDownloadRequestModel(
            environment = env,
            clientId = getClientId(),
            scope = DOCUMENT_SIGNING_SCOPE,
            documentName = documentName,
            documentURL = documentURL ?: ""
        )
    }
}
