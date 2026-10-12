import SwiftUI

struct ProfileScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            Text("Profile")
                .font(LumenFont.font(24, .semibold))
                .foregroundStyle(Theme.text)

            HStack(spacing: Theme.spaceLG) {
                Circle()
                    .fill(Theme.primary.opacity(0.25))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Text("A")
                            .font(LumenFont.font(20, .semibold))
                            .foregroundStyle(Theme.text)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Admin")
                        .font(LumenFont.font(17, .medium))
                        .foregroundStyle(Theme.text)
                    Text(model.email)
                        .font(LumenFont.font(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(Theme.spaceXL)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workspace")
                        .font(LumenFont.font(12, .medium))
                        .foregroundStyle(Theme.textTertiary)
                    Text(model.workspaceAddress)
                        .font(LumenFont.font(15, .medium))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                }
                Spacer()
                Button("Switch") {
                    model.password = ""
                    model.showWorkspaceSwitch = true
                }
                .font(LumenFont.font(14, .medium))
                .foregroundStyle(Theme.primarySoft)
            }
            .padding(Theme.spaceXL)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))

            findingPreview

            Button {
                model.password = ""
                model.signedIn = false
            } label: {
                Text("Sign out")
                    .font(LumenFont.font(15, .medium))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .glassEffect(.regular.interactive(), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, Theme.spaceXL)
        .padding(.top, Theme.spaceMD)
        .fullScreenCover(isPresented: Bindable(model).showWorkspaceSwitch) {
            SignInScreen(
                onCancel: { model.showWorkspaceSwitch = false },
                onSignedIn: { model.showWorkspaceSwitch = false }
            )
        }
    }

    /// Prototype control. Findings arrive on their own; this only previews the two states.
    private var findingPreview: some View {
        VStack(alignment: .leading, spacing: Theme.spaceLG) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Findings")
                    .font(LumenFont.font(12, .medium))
                    .foregroundStyle(Theme.textTertiary)
                Text("The rim plays, then the finding appears.")
                    .font(LumenFont.font(15, .medium))
                    .foregroundStyle(Theme.text)
            }
            HStack(spacing: Theme.spaceMD) {
                previewButton("Toast", mode: .chip)
                previewButton("Aurora", mode: .alert)
                previewButton("Off", mode: .off)
            }
        }
        .padding(Theme.spaceXL)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func previewButton(_ title: String, mode: FindingAuroraMode) -> some View {
        let selected = model.findingRequest == mode
        return Button {
            model.presentFinding(mode)
        } label: {
            Text(title)
                .font(LumenFont.font(14, .medium))
                .foregroundStyle(selected ? Color.black : Theme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .glassEffect(
                    selected ? .regular.tint(Theme.primary).interactive() : .regular.interactive(),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
