package uz.app.shieldguard

internal data class GateDecision(val blocked: Boolean, val outcome: String) {
    fun asMap() = mapOf("blocked" to blocked, "outcome" to outcome)
}

internal object ApkAlertPolicy {
    fun allowed(enabled: Boolean, consent: Boolean, permission: Boolean, channel: Boolean, risk: String) =
        enabled && consent && permission && channel && risk in setOf("strongSuspicion", "confirmedHighConfidenceThreat")
}

internal object AutomaticBlockEngine {
    fun decide(assessment: ApkAssessment, actualApk: Boolean, enabled: Boolean, strict: Boolean): GateDecision = when {
        !actualApk -> GateDecision(true, "scanIncomplete")
        enabled && assessment.risk in setOf("confirmedHighConfidenceThreat", "strongSuspicion") ->
            GateDecision(true, "blockedByShieldGuard")
        strict && !assessment.complete -> GateDecision(true, "scanIncomplete")
        else -> GateDecision(false, "warningOnly")
    }
    // Used only at an explicit user request; no constructor/scan has a launch side effect.
    fun forward(decision: GateDecision, approved: Boolean, launch: () -> Unit): Boolean {
        if (decision.blocked || !approved) return false
        launch()
        return true
    }
}
