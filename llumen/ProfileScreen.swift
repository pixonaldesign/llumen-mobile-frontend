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
            .background(Theme.fillQuiet, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            }

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
                    model.signedIn = false
                }
                .font(LumenFont.font(14, .medium))
                .foregroundStyle(Theme.primarySoft)
            }
            .padding(Theme.spaceXL)
            .background(Theme.fillQuiet, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            }

            Button {
                model.password = ""
                model.signedIn = false
            } label: {
                Text("Sign out")
                    .font(LumenFont.font(15, .medium))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.fillQuiet, in: RoundedRectangle(cornerRadius: Theme.radiusUI, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.radiusUI, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, Theme.spaceXL)
        .padding(.top, Theme.spaceMD)
    }
}
