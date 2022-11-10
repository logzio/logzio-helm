module github.com/logzio/app-type-detector/appDetector

go 1.18

require (
	github.com/fntlnz/mountinfo v0.0.0-20171106231217-40cb42681fad
	github.com/logzio/app-type-detector/common v0.0.0
)

replace github.com/logzio/app-type-detector/common => ./../common
