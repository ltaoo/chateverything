import SwiftUI

struct RoleDetailView: View {
    let role: RoleBiz
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(role.name)
                .font(.title)
                .padding()
            
            Spacer()
        }
        .navigationTitle("角色详情")
    }
}

