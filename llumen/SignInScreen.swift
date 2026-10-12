import SwiftUI
import UIKit

struct SignInScreen: View {
    @Environment(AppModel.self) private var model
    @FocusState private var field: Field?
    var onCancel: (() -> Void)? = nil
    var onSignedIn: (() -> Void)? = nil

    private enum Field: Hashable { case address, email, password }

    var body: some View {
        @Bindable var model = model
        LlumenBackground {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Theme.space3XL) {
                        if onCancel != nil {
                            HStack {
                                Button {
                                    onCancel?()
                                } label: {
                                    HStack(spacing: 6) {
                                        PhosphorIcon(.caretLeft, size: 14)
                                        Text("Back")
                                            .font(LumenFont.font(15, .medium))
                                    }
                                    .foregroundStyle(Theme.text)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Back")
                                Spacer()
                            }
                        }
                        Image("LlumenLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                            .padding(.top, Theme.space4XL)
                        Text("Sign in to your workspace")
                            .font(LumenFont.font(16, .medium))
                            .foregroundStyle(Theme.textSecondary)

                        VStack(alignment: .leading, spacing: Theme.spaceXL) {
                            fieldBlock("Workspace address", text: $model.workspaceAddress, id: .address, secure: false)
                            fieldBlock("Email", text: $model.email, id: .email, secure: false)
                            fieldBlock("Password", text: $model.password, id: .password, secure: true)
                            Button {
                                model.signedIn = true
                                onSignedIn?()
                            } label: {
                                Text("Sign in")
                                    .font(LumenFont.font(16, .medium))
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .blueGlass()
                            }
                            .buttonStyle(.plain)
                            Button {
                                model.showPasswordHelp = true
                            } label: {
                                Text("Forgot your password?")
                                    .font(LumenFont.font(13, .medium))
                                    .foregroundStyle(Theme.primarySoft)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(Theme.spaceXL)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                    }
                    .padding(.horizontal, Theme.spaceXL)
                    .padding(.bottom, Theme.space4XL)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: field) { _, focused in
                    guard let focused else { return }
                    withAnimation(Theme.motion) {
                        proxy.scrollTo(focused, anchor: .center)
                    }
                }
            }
        }
        .sheet(isPresented: Bindable(model).showPasswordHelp) {
            PasswordHelpSheet()
                .presentationDetents([.medium])
                .presentationBackground(Theme.background)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { field = nil }
            }
        }
    }

    private func fieldBlock(_ title: String, text: Binding<String>, id: Field, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(LumenFont.font(12, .medium))
                .foregroundStyle(Theme.textTertiary)
            Group {
                if secure {
                    SecureField("Password", text: text)
                } else {
                    TextField(title, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .focused($field, equals: id)
            .font(LumenFont.font(16))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusUI, style: .continuous))
        }
        .id(id)
    }
}

private struct PasswordHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    private let admin = "admin@llumen.io"

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            Text("Password resets are handled by your workspace admin.")
                .font(LumenFont.font(18, .medium))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(admin)
                .font(LumenFont.font(16))
                .foregroundStyle(Theme.primarySoft)
            Button {
                UIPasteboard.general.string = admin
                copied = true
            } label: {
                Text(copied ? "Copied" : "Copy admin address")
                    .font(LumenFont.font(15, .medium))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .blueGlass()
            }
            .buttonStyle(.plain)
            Button("Close") { dismiss() }
                .font(LumenFont.font(15, .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(Theme.space3XL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
    }
}
