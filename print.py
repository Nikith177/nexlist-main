with open('lib/features/listing/presentation/listing_detail_screen.dart') as f:
    lines = f.read().split('\n')
for i in range(417, 425):
    print(f"{i+1:3d}: {lines[i]}")
print("...")
for i in range(830, 843):
    print(f"{i+1:3d}: {lines[i]}")
