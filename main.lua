function cloneCircleImage(image)
  local clone = {}

  for i, circle in ipairs(image) do
    clone[i] = {unpack(circle)}
  end

  return clone
end

function generateCircle()
  local x = love.math.random()
  local y = love.math.random()
  local radius = love.math.random()

  local red = love.math.random()
  local green = love.math.random()
  local blue = love.math.random()
  local alpha = love.math.random()

  return {x, y, radius, red, green, blue, alpha}
end

function clamp(x, x1, x2)
  return math.min(math.max(x, x1), x2)
end

function mutateCircle(circle)
  local i = love.math.random(1, #circle)
  local stddev = 1 / 16 * love.math.random()
  circle[i] = clamp(love.math.randomNormal(stddev, circle[i]), 0, 1)
end

function mutateCircleImage(image)
  local i = love.math.random(1, 16)

  if i == 1 then
    -- Add circle
    if #image < 65536 then
      local j = love.math.random(1, #image + 1)
      local circle = generateCircle()
      table.insert(image, j, circle)
    end
  elseif i == 2 then
    -- Remove circle
    if #image >= 1 then
      local j = love.math.random(1, #image)
      table.remove(image, j)
    end
  elseif i == 3 then
    -- Replace circle
    if #image >= 1 then
      local j = love.math.random(1, #image)
      image[j] = generateCircle()
    end
  elseif i == 4 then
    -- Swap circles
    if #image >= 2 then
      local j = love.math.random(1, #image - 1)
      local k = love.math.random(j + 1, #image)
      image[j], image[k] = image[k], image[j]
    end
  else
    -- Mutate circle
    if #image >= 1 then
      local j = love.math.random(1, #image)
      mutateCircle(image[j])
    end
  end
end

function love.load()
  love.window.setTitle("Straw")
  love.window.setMode(1024, 512)
  parent = {}
  referenceImageData = love.image.newImageData("strawberries-512.png")
  referenceImage = love.graphics.newImage(referenceImageData)
end

local function drawCircleImageToCanvas(image, canvas)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  local width, height = canvas:getDimensions()
  love.graphics.scale(width, height)

  for i, circle in ipairs(image) do
    local x, y, radius, red, green, blue, alpha = unpack(circle)
    love.graphics.setColor(red, green, blue, alpha)
    love.graphics.circle("fill", x, y, radius)
  end

  love.graphics.setCanvas()
end

local function getDistance(image1, image2)
  local width1, height1 = image1:getDimensions()
  local width2, height2 = image2:getDimensions()
  assert(width1 == width2 and height1 == height2)

  local totalDistance = 0

  for y = 0, height1 - 1 do
    for x = 0, width1 - 1 do
      local r1, g1, b1, a1 = image1:getPixel(x, y)
      local r2, g2, b2, a2 = image2:getPixel(x, y)

      distance = (0.25 * ((r2 - r1) ^ 2 + (g2 - g1) ^ 2 + (b2 - b1) ^ 2 + (a2 - a1) ^ 2)) ^ 0.5
      totalDistance = totalDistance + distance
    end
  end

  return totalDistance / (width1 * height1)
end

function love.draw()
  if not canvas then
    canvas = love.graphics.newCanvas(512, 512)
    drawCircleImageToCanvas(parent, canvas)
    local parentImageData = canvas:newImageData()
    parentFitness = getDistance(parentImageData, referenceImageData)
    parentImage = love.graphics.newImage(parentImageData)
  end

  love.graphics.reset()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(referenceImage, 0, 0)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(parentImage, 512, 0)

  local child = cloneCircleImage(parent)
  mutateCircleImage(child)

  drawCircleImageToCanvas(child, canvas)
  local childImageData = canvas:newImageData()
  local childFitness = getDistance(childImageData, referenceImageData)

  if childFitness < parentFitness then
    parent = child
    parentFitness = childFitness
    parentImage = love.graphics.newImage(childImageData)
  end
end
