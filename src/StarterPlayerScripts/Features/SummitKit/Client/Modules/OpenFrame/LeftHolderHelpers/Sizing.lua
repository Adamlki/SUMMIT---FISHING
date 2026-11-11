--!nonstrict
local Sizing = {}

function Sizing.scaleUDim2(size, scale)
	return UDim2.new(
		size.X.Scale * scale,
		size.X.Offset * scale,
		size.Y.Scale * scale,
		size.Y.Offset * scale
	)
end

return Sizing
