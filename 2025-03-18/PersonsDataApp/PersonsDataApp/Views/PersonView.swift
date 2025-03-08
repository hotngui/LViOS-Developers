import SwiftUI
import Kingfisher

struct PersonView: View {
    let person: Person
    private let avatarSize: CGFloat = 50
    
    var body: some View {
        HStack(spacing: 6) {
            // Avatar image
            KFImage(person.avatarURL)
                .placeholder {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .frame(width: avatarSize, height: avatarSize)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
            
            // Person details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(person.lastName), \(person.firstName)")
                    .font(.headline)
                
                Text(person.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PersonView(person: Person(
        id: UUID(),
        firstName: "John",
        lastName: "Doe",
        address: "123 Main St, City, Country",
        avatarURL: nil
    ))
}
