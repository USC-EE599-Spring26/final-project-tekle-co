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
                MultipleChoiceQuestionView(question: self, choices: choices)
            } else {
                Text(title).questionContainerStyle()
            }
        case .slider:
            SliderQuestionView(question: self)
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

private struct MultipleChoiceQuestionView: View {
    let question: SurveyQuestion
    let choices: [TextChoice]
    @State private var selectedChoiceIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(choices) { choice in
                Button {
                    toggleChoice(choice.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedChoiceIDs.contains(choice.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedChoiceIDs.contains(choice.id) ? .accent : .secondary)
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
                .buttonStyle(.plain)
                .accessibilityLabel(choice.choiceText)
            }
        }
        .questionContainerStyle()
    }

    private func toggleChoice(_ id: String) {
        if question.choiceSelectionLimit == .single {
            selectedChoiceIDs = [id]
            return
        }
        if selectedChoiceIDs.contains(id) {
            selectedChoiceIDs.remove(id)
        } else {
            selectedChoiceIDs.insert(id)
        }
    }
}

private struct SliderQuestionView: View {
    let question: SurveyQuestion
    @State private var sliderValue: Double

    init(question: SurveyQuestion) {
        self.question = question
        let lower = Double(question.integerRange?.lowerBound ?? 0)
        _sliderValue = State(initialValue: lower)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let detail = question.detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            let lower = Double(question.integerRange?.lowerBound ?? 0)
            let upper = Double(question.integerRange?.upperBound ?? 10)
            let step = Double(question.sliderStepValue ?? 1)

            Slider(
                value: $sliderValue,
                in: lower...upper,
                step: step
            )
            .tint(.accentColor)

            HStack {
                Text("\(Int(lower))")
                Spacer()
                Text("\(Int(sliderValue))")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(upper))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .questionContainerStyle()
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
