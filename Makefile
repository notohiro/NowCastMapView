PROJECT = NowCastMapView.xcodeproj

clean:
	xcodebuild \
	-project $(PROJECT) \
	clean

test:
	xcrun simctl list
	brew update
	brew install carthage
	carthage update
	xcodebuild \
	-project $(PROJECT) \
	-scheme NowCastMapViewTests \
	-configuration Debug \
	-destination 'platform=iOS Simulator,name=iPhone 6' \
	test
