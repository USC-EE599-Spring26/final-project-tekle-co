//
//  Consent.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length
let informedConsentHTML = """
    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta charset="utf-8" />
        <style type="text/css">
            ul, p, h1, h3 {
                text-align: left;
            }
        </style>
    </head>
    <body>
        <h1>Informed Consent</h1>
        <h3>About This Study</h3>
        <p>This app is designed to help individuals with ADHD track their mood, medication adherence, and cognitive patterns over time. Your participation will help researchers better understand how ADHD symptoms fluctuate day to day.</p>
        <h3>Study Expectations</h3>
        <ul>
            <li>You will be asked to log your mood, focus level, and medication intake daily.</li>
            <li>The study will send you notifications to remind you to complete these tasks.</li>
            <li>You will be asked to share select health data to support the study goals.</li>
            <li>The study is expected to last 1 semester.</li>
            <li>Your information will be kept private and secure.</li>
            <li>You can withdraw from the study at any time.</li>
        </ul>
        <h3>Eligibility Requirements</h3>
        <ul>
            <li>Must be 18 years or older.</li>
            <li>Must be able to read and understand English.</li>
            <li>Must be the only user of the device on which you are participating in the study.</li>
            <li>Must be able to sign your own consent form.</li>
        </ul>
        <p>By signing below, I acknowledge that I have read this consent carefully, that I understand all of its terms, and that I enter into this study voluntarily. I understand that my information will only be used and disclosed for the purposes described in the consent and I can withdraw from the study at any time.</p>
        <p>Please sign using your finger below.</p>
        <br>
    </body>
    </html>
    """
