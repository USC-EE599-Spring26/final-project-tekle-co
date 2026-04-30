//
//  Consent.swift
//  OCKSample
//
//  ADHD Comedown Tracker — Informed Consent
//

import Foundation

private let consentSigningParagraph = "<p>By signing below, I acknowledge that I have read this consent "
    + "carefully, that I understand all of its terms, and that I am voluntarily choosing to use "
    + "this application. I understand that my health and tracking data will only be used to help me "
    + "understand my personal ADHD medication comedown patterns, and I can stop using the app at any time.</p>"

let informedConsentHTML = """
    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta name="viewport" content="width=400, user-scalable=no">
        <meta charset="utf-8" />
        <style type="text/css">
            ul, p, h1, h3 {
                text-align: left;
            }
        </style>
    </head>
    <body>
        <h1>ADHD Comedown Tracker — Informed Consent</h1>
        <h3>What This App Does</h3>
        <ul>
            <li>Tracks your ADHD medication schedule and comedown severity over time.</li>
            <li>Logs lifestyle factors like meals, hydration, exercise, and focus activities.</li>
            <li>Helps you visualize which habits correlate with better or worse comedowns.</li>
            <li>Uses HealthKit data (steps, water intake, heart rate) to supplement your logs.</li>
        </ul>
        <h3>What We Ask of You</h3>
        <ul>
            <li>Log your medication timing and comedown severity daily.</li>
            <li>Complete brief check-ins about your mood, focus, and energy.</li>
            <li>Optionally log meals, exercise, and focus activities for deeper insights.</li>
            <li>Share relevant health data from Apple Health to enrich your tracking.</li>
        </ul>
        <h3>Your Privacy</h3>
        <ul>
            <li>Your data is stored securely and is private to you.</li>
            <li>We do not sell or share your health information with third parties.</li>
            <li>You can delete your data or stop using the app at any time.</li>
        </ul>
        <h3>Eligibility</h3>
        <ul>
            <li>Must be 18 years or older.</li>
            <li>Must be the only user of this device for tracking purposes.</li>
            <li>This app is not a substitute for professional medical advice.</li>
        </ul>
        \(consentSigningParagraph)
        <p>Please sign using your finger below.</p>
        <br>
    </body>
    </html>
    """
