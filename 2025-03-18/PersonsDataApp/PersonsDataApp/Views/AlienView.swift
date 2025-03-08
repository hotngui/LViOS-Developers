import SwiftUI
import Kingfisher

struct AlienView: View {
    let alien: Alien
    private let avatarSize: CGFloat = 50
    
    var body: some View {
        HStack(spacing: 6) {
            // Avatar image
            KFImage(alien.avatarURL)
                .placeholder {
                    Image(systemName: "figure.2.circle.fill")
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
            
            // Alien details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(alien.lastName), \(alien.firstName)")
                    .font(.headline)
                
                Text(alien.planet)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AlienView(alien: Alien(
        id: UUID(),
        firstName: "Zorg",
        lastName: "Xylophone",
        planet: "Galaxy X23, Sector 7, Planet Z",
        avatarURL: nil
    ))
} 
