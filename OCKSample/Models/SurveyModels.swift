//
//  SurveyModels.swift
//  OCKSample
//
//  Created by Cursor on 3/24/26.
//

import Foundation
import SwiftUI
import ResearchKitSwiftUI

enum SurveyQuestionType: String, Codable {
    case multipleChoice
    case slider
}

enum ChoiceSelectionLimit: String, Codable {
    case single
    case multiple
}

struct TextChoice: Codable, Identifiable {
    let id: String
    let choiceText: String
    let value: String
}

struct SurveyQuestion: Codable, Identifiable {
    let id: String
    let type: SurveyQuestionType
    let required: Bool
    let title: String
    let detail: String?
    let textChoices: [TextChoice]?
    let choiceSelectionLimit: ChoiceSelectionLimit?
    let integerRange: ClosedRange<Int>?
    let sliderStepValue: Int?

    init(
        id: String,
        type: SurveyQuestionType,
        required: Bool,
        title: String,
        detail: String? = nil,
        textChoices: [TextChoice]? = nil,
        choiceSelectionLimit: ChoiceSelectionLimit? = nil,
        integerRange: ClosedRange<Int>? = nil,
        sliderStepValue: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.required = required
        self.title = title
        self.detail = detail
        self.textChoices = textChoices
        self.choiceSelectionLimit = choiceSelectionLimit
        self.integerRange = integerRange
        self.sliderStepValue = sliderStepValue
    }

    @ViewBuilder
    @MainActor
    func view() -> some View {
        switch type {
        case .multipleChoice:
            if let choices = textChoices {
                VStack(alignment: .leading, spacing: 12) {
                    questionHeader
                    ForEach(choices) { choice in
                        HStack(spacing: 10) {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Text(choice.choiceText)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .questionContainerStyle()
            } else {
                Text(title).questionContainerStyle()
            }
        case .slider:
            VStack(alignment: .leading, spacing: 12) {
                questionHeader
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let integerRange {
                    HStack {
                        Text("\(integerRange.lowerBound)")
                        Spacer()
                        Text("\(integerRange.upperBound)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .questionContainerStyle()
        }
    }

    @ViewBuilder
    @MainActor
    private var questionHeader: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SurveyStep: Codable, Identifiable {
    let id: String
    let questions: [SurveyQuestion]
}

private extension View {
    @MainActor
    func questionContainerStyle() -> some View {
        self
            .padding(14)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
    }
}
