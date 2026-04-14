//
//  SurveyModels.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/12/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import SwiftUI
// swiftlint:disable line_length
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
        #if !os(watchOS)
        switch type {
        case .multipleChoice:
            if let choices = textChoices {
                MultipleChoiceQuestionView(question: self, choices: choices)
            } else {
                Text(title)
            }
        case .slider:
            SliderQuestionView(question: self)
        }
        #else
        Text(title)
        #endif
    }
}
#if !os(watchOS)
private struct MultipleChoiceQuestionView: View {
    let question: SurveyQuestion
    let choices: [TextChoice]
    @State private var selectedChoiceIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(question.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if question.required {
                    Text("Required")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 8) {
                ForEach(choices) { choice in
                    Button {
                        toggleChoice(choice.id)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        selectedChoiceIDs.contains(choice.id) ? Color.accentColor : Color.secondary.opacity(0.4),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 22, height: 22)
                                if selectedChoiceIDs.contains(choice.id) {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            Text(choice.choiceText)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedChoiceIDs.contains(choice.id)
                                      ? Color.accentColor.opacity(0.08)
                                      : Color(uiColor: .secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    selectedChoiceIDs.contains(choice.id)
                                    ? Color.accentColor.opacity(0.3)
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(choice.choiceText)
                }
            }
        }
        .surveyContainerStyle()
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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(question.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = question.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            let lower = Double(question.integerRange?.lowerBound ?? 0)
            let upper = Double(question.integerRange?.upperBound ?? 10)
            let step = Double(question.sliderStepValue ?? 1)

            VStack(spacing: 8) {
                Slider(value: $sliderValue, in: lower...upper, step: step)
                    .tint(.accentColor)
                HStack {
                    Text("\(Int(lower))")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(sliderValue))")
                        .font(.title3.weight(.bold))
                        .contentTransition(.numericText())
                    Spacer()
                    Text("\(Int(upper))")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .surveyContainerStyle()
    }
}

struct SurveyStep: Codable, Identifiable {
    let id: String
    let questions: [SurveyQuestion]
}

private extension View {
    @MainActor
    func surveyContainerStyle() -> some View {
        self
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
#endif
// swiftlint:enable line_length
