matrix = require "matrix"

function love.load()
    points={
        {320,240,0},
        {240,320,0},
        {320,320,0},
        {240,240,320},
    }
    edges = {
        {1,2},
        {2,3},
        {3,4},
        {4,1},
    }

    tris = {
        {1,2,3},
        {2,3,4},
        {1,2,4},
        {1,3,4},
    }

    tets = {
        {1,2,3,4}
    }

    for k,p in pairs(points) do
        p.alpha=100
        p.radius=20
    end

    font=love.graphics.setNewFont(12)
    fps_text=love.graphics.newText(font, "0")
    t=0

    update_tris()
end

function update_tris()
    for k,v in pairs(tris) do
        v.cm=CayleyMenger(2,v,points)
        v.icm=matrix.invert(v.cm)
    end

    for k,v in pairs(tets) do
        v.cm=CayleyMenger(3,v,points)
        v.icm=matrix.invert(v.cm)
    end
end

function CayleyMenger(ndim,simplex,points)
    function dist(i,j)
        local d = 0
        for k=1,ndim do
            local delta=points[simplex[i]][k]-points[simplex[j]][k]
            d=d+delta*delta
        end
        return d
    end

    local N=ndim+2
    local m={}

    for i=1,N do
        m[i]={}   -- init storage for columns
    end

    for i=1,N do
        for j=1,N do
            m[i][j]=100
        end
        m[i][i]=0 -- set diag to 0
    end

    -- init top and left
    for i=2,N do
        m[1][i]=1
        m[i][1]=1
    end

    -- compute distances
    for i=1,ndim do
        for j=i+1,ndim+1 do
            local d=dist(i,j)
            m[i+1][j+1]=d
            m[j+1][i+1]=d
        end
    end

    return m
end

function draw_matrix(n,m,x,y)
    if not m then return end
    local dx,dy=80,20
    for i=1,n do
        for j=1,n do
            love.graphics.print(string.format("%4.2f",m[i][j]),x+j*dx,y+i*dy)
        end
    end
end

function radius(inverse_cayley_menger)
    if not inverse_cayley_menger then return 0 end
    return math.sqrt(-inverse_cayley_menger[1][1]/2)
end

function center(ndim,inverse_cayley_menger,simplex,ps)
    if not inverse_cayley_menger then return nil end
    r={}
    for i=1,ndim do r[i]=0 end
    for i=1,ndim+1 do
        for d=1,ndim do
            r[d]=r[d]+ps[simplex[i]][d]*inverse_cayley_menger[1][i+1]
        end
    end
    return r
end

function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255
end

function love.draw()
    -- draw_matrix(4,tris[1].icm,10,30)

    for k,v in ipairs(tris) do
        local R=radius(v.icm)
        local C=center(2,v.icm,v,points)
        if C then
            local r,g,b=HSV(255*k/#tris,255,255)
            love.graphics.setColor(r,g,b,255)
            love.graphics.circle("fill", C[1],C[2], 2, 72)
            love.graphics.setColor(r,g,b,155)
            love.graphics.circle("line", C[1],C[2], R, 72)
        end
    end

    for k,v in ipairs(tets) do
        local R=radius(v.icm)
        local C=center(3,v.icm,v,points)
        if C then
            local r,g,b=155,155,155 -- HSV(255*k/#tets,255,255)
            love.graphics.setColor(r,g,b,255)
            love.graphics.circle("fill", C[1],C[2], 2, 72)
            love.graphics.setColor(r,g,b,55)
            love.graphics.circle("fill", C[1],C[2], R, 72)
        end
    end

    for k,a in pairs(points) do
        love.graphics.setColor(255, 255, 255)
        love.graphics.circle("fill", a[1], a[2], 2, 36)

        if a.pressed then
            love.graphics.circle("line", a[1], a[2], a.radius, 36)
            love.graphics.setColor(255, 255, 0)
            love.graphics.circle("fill", a[1]+a.pressed[1], a[2]+a.pressed[2], 2, 36)
        end
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(fps_text,10,10)
end

function love.update(dt)
    t=t+dt
    fps_text=love.graphics.newText(font, string.format("FPS %3.1f",1/dt))
end

function love.mousepressed(x, y, button, isTouch)
    for k,a in pairs(points) do
        if not a.pressed then
            local dx=x-a[1]
            local dy=y-a[2]
            local r2=dx*dx+dy*dy
            if r2<a.radius*a.radius then
                a.pressed={dx,dy}
                a.pressed.button=button
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    function clamp(v,mx)
        if v<0 then return 0 end
        if v>mx then return mx end
        return v
    end
    for k,a in pairs(points) do
        if a.pressed then
            local w,h=love.graphics.getDimensions()
            a[1]=clamp(x-a.pressed[1],w)
            a[2]=clamp(y-a.pressed[2],h)
        end
    end
    update_tris()
end

function love.mousereleased(x, y, button, isTouch)
    for k,a in pairs(points) do
        if a.pressed then
            a.pressed=nil
        end
    end
end

function love.mousefocus(focus)
    if not focus then
        for k,a in pairs(points) do
            if a.pressed then
                a.pressed=nil
            end
        end
    end
end
