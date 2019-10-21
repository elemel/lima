function saveCircleImage(image, filename)
  local file = io.open(filename, "w")
  file:write("return {\n")

  for i, circle in ipairs(image) do
    local x, y, diameter, red, green, blue, alpha = unpack(circle)
    file:write("  {" ..
      x .. ", " ..
      y .. ", " ..
      diameter .. ", " ..
      red .. ", " ..
      green .. ", " ..
      blue .. ", " ..
      alpha .. "},\n")
  end

  file:write("}\n")
  file:close()
end

function cloneCircleImage(image)
  local clone = {}

  for i, circle in ipairs(image) do
    clone[i] = {unpack(circle)}
  end

  return clone
end

function randomByte()
  return love.math.random(0, 255)
end

function generateCircle()
  local x = randomByte()
  local y = randomByte()
  local diameter = randomByte()

  local red = randomByte()
  local green = randomByte()
  local blue = randomByte()
  local alpha = randomByte()

  return {x, y, diameter, red, green, blue, alpha}
end

function generateCircleImage(size)
  local image = {}

  for i = 1, size do
    image[i] = generateCircle()
  end

  return image
end

function mutateCircleByte(circle)
  local i = love.math.random(1, #circle)
  circle[i] = randomByte()
end

function mutateCircleBit(circle)
  local i = love.math.random(1, #circle)
  local j = love.math.random(0, 7)
  circle[i] = bit.bxor(circle[i], bit.lshift(1, j))
end

function mutateCircleImage(image)
  local i = love.math.random(1, 4)

  if i == 1 then
    -- Replace image
    for j = 1, #image do
      image[j] = generateCircle()
    end
  elseif i == 2 then
    -- Replace circle
    local j = love.math.random(1, #image)
    local k = love.math.random(1, #image)
    local circle = generateCircle()
    table.remove(image, j)
    table.insert(image, k, circle)
  elseif i == 3 then
    -- Replace circle byte
    local j = love.math.random(1, #image)
    mutateCircleByte(image[j])
  else
    -- Replace circle bit
    local j = love.math.random(1, #image)
    mutateCircleBit(image[j])
  end
end

function love.load(arg)
  if #arg ~= 3 or arg[1] ~= "evolve" then
    print("Usage: love . evolve <source> <target>")
    love.event.quit(1)
    return
  end

  _, sourceFilename, targetFilename = unpack(arg)

  love.window.setTitle("Lima")
  love.window.setMode(1024, 512)
  referenceImageData = love.image.newImageData(sourceFilename)
  referenceImage = love.graphics.newImage(referenceImageData)

  print("Loading...")
  local success, result = pcall(dofile, targetFilename)

  if success then
    parent = result
  else
    print("Loading error: " .. result)
    parent = generateCircleImage(256)
  end
end

local function drawCircleImageToCanvas(image, canvas)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  local width, height = canvas:getDimensions()
  love.graphics.scale(width, height)

  for i, circle in ipairs(image) do
    local x, y, diameter, red, green, blue, alpha = unpack(circle)
    love.graphics.setColor(red / 255, green / 255, blue / 255, alpha / 255)
    love.graphics.circle("fill", x / 255, y / 255, 0.5 * diameter / 255)
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
    print("Fitness: " .. parentFitness)
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

    print("Fitness: " .. parentFitness)
    saveCircleImage(parent, targetFilename)
  end
end

function love.quit()
  if parent and targetFilename then
    print("Saving...")
    saveCircleImage(parent, targetFilename)
  end
end
