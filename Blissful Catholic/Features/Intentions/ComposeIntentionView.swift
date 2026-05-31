//
//  ComposeIntentionView.swift
//  Blissful Catholic
//
//  Sheet for creating or editing a prayer intention. Used both for new entries
//  (no argument) and editing an existing one (pass the Intention). When editing,
//  also surfaces "Mark as Answered" / "Reactivate" and "Delete" actions.
//

import SwiftUI
import SwiftData

struct ComposeIntentionView: View {
    /// When set, we're editing an existing intention rather than creating one.
    var intention: Intention? = nil

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var text = ""
    @State private var loaded = false
    @State private var showDeleteConfirm = false
    @FocusState private var focused: Bool

    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            LumenDeepHeader(eyebrow: intention == nil ? "New Intention" : "Edit Intention",
                            title: "Prayer Intention",
                            onBack: { dismiss() }) {
                Button { save() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(hasContent ? pal.accent : t.surface3, in: .circle)
                }
                .buttonStyle(.plain)
                .disabled(!hasContent)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Who or what do you want to pray for?")
                        .font(LumenType.serif(15).italic())
                        .foregroundStyle(t.inkMid)
                        .padding(.top, 20)

                    TextField("",
                              text: $text,
                              prompt: Text("For…").foregroundStyle(t.inkSoft),
                              axis: .vertical)
                        .font(LumenType.display(22).italic())
                        .foregroundStyle(t.ink)
                        .focused($focused)
                        .lineSpacing(6)
                        .padding(16)
                        .frame(minHeight: 140, alignment: .topLeading)
                        .background(t.surface, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))

                    if let intention {
                        intentionActions(intention)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: loadOnce)
        .confirmationDialog("Delete this intention?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let intention {
                    context.delete(intention)
                    try? context.save()
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Actions (only when editing)

    @ViewBuilder
    private func intentionActions(_ intention: Intention) -> some View {
        VStack(spacing: 10) {
            if intention.isActive {
                actionButton(title: "Mark as Answered", systemImage: "checkmark.circle",
                             tint: pal.accent) {
                    intention.completedAt = .now
                    try? context.save()
                    dismiss()
                }
            } else {
                actionButton(title: "Reactivate", systemImage: "flame",
                             tint: pal.accent) {
                    intention.completedAt = nil
                    try? context.save()
                    dismiss()
                }
            }

            actionButton(title: "Delete", systemImage: "trash",
                         tint: .red.opacity(0.8),
                         border: .red.opacity(0.4)) {
                showDeleteConfirm = true
            }
        }
        .padding(.top, 24)
    }

    private func actionButton(title: String, systemImage: String,
                              tint: Color, border: Color? = nil,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(LumenType.ui(13, weight: .medium))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(t.surface, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(border ?? tint, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: Persistence

    private func loadOnce() {
        if !loaded, let intention {
            text = intention.text
        }
        loaded = true
        focused = true
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let intention {
            intention.text = trimmed
        } else {
            let new = Intention()
            new.text = trimmed
            new.createdAt = .now
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    ComposeIntentionView()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.ordinaryTime))
        .modelContainer(PreviewSupport.container)
}
