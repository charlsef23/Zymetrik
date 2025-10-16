import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.presentationMode) private var presentationMode
    let isModal: Bool

    var body: some View {
        Group {
            if isModal {
                content
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
            } else {
                content
                    .navigationTitle("Terms & Conditions")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms & Conditions")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)

                Text(termsText)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
    }

    private var termsText: String {
        """
        Welcome to our application.

        By using our app, you agree to the following terms and conditions:

        1. Acceptance of Terms
        You agree to comply with and be bound by these terms.

        2. Use License
        Permission is granted to temporarily download one copy of the materials.

        3. Disclaimer
        The materials are provided on an 'as is' basis without warranties.

        4. Limitations
        In no event shall we be liable for any damages arising out of use.

        5. Modifications
        We may revise these terms at any time without notice.

        6. Governing Law
        These terms are governed by the laws of the applicable jurisdiction.

        Please read these terms carefully before using our service.
        """
    }
}

struct TermsAndConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TermsAndConditionsView(isModal: false)
        }
        TermsAndConditionsView(isModal: true)
    }
}
