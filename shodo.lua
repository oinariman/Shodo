-- shodo 1.0.1
-- by ryosuke mihara

-- brush attributes
--
-- x    : x-coordinate
-- y    : y-coordinate
-- vx   : x component of velocity
-- vy   : y component of velocity
-- down : when true, the brush is put down to the paper
-- r    : brush thickness
brush={}
brush.x=64
brush.y=64
brush.vx=0
brush.vy=0
brush.down=false
brush.r=0

-- brush constants
--
-- brush_acc   : accelaration
-- brush_brake : brake value
-- brush_mul   : speed magnification when the brush is down
-- brush_rmax  : maximum thickness
-- bursh_racc  : acceralation of thickness changes
brush_acc=0.175
brush_brake=-0.1
brush_mul=0.65
brush_rmax=3
brush_racc=0.2

-- paper attributes & constants
paper={}
paper.y=0
paper.vy=0
paper_init_vy=5
paper_acc=0.3

----

function replace_paper()
  if paper.y>0 then
    rectfill(0,0,127,127,7)
    local y=flr(paper.y)
    memcpy(0x6000,0x1000+y*64,64*(128-y))
    line(0,127-y-1,127,127-y-1,6)

    paper.y+=paper.vy
    paper.vy+=paper_acc
    if paper.y>=127 then
      memset(0x1000,0x0077,128*64)
      paper.y=0
    end
  end
end

----

function draw_brush()
  if brush.down then
    spr(3,brush.x,brush.y-23,1,3)
    spr(2,brush.x,brush.y)
  else
    spr(3,brush.x,brush.y-24,1,3)
    spr(1,brush.x,brush.y)
  end
end

function draw_line()
  if brush.r>0 then
    circfill(brush.x+4,brush.y+6,brush.r,0)
  end
end

----

function move_brush()
  -- when the brush is put down to the paper, slow its speed
  local mul=1
  if brush.down then
    mul=brush_mul
  end
  brush.x+=brush.vx*mul
  brush.y+=brush.vy*mul

  -- brake the brush
  -- stop the brush when its x/y component of velocity is inverted
  local prev
  if brush.vx ~= 0 then
    prev = brush.vx
    brush.vx += brush.vx * brush_brake
    if prev*brush.vx<0 then brush.vx = 0 end
  end
  if brush.vy ~= 0 then
    prev = brush.vy
    brush.vy += brush.vy * brush_brake
    if prev*brush.vy<0 then brush.vy = 0 end
  end

  -- stop the brush when it reaches the edge of the screen
  if brush.x<-4 then brush.x=-4 end
  if brush.x>123 then brush.x=123 end
  if brush.y<-6 then brush.y=-6 end
  if brush.y>123 then brush.y=123 end
end

function update_line_width()
 if brush.down then
  brush.r+=brush_racc
 else
  brush.r-=brush_racc
 end
 if brush.r<0 then brush.r=0 end
 if brush.r>brush_rmax then brush.r=brush_rmax end
end

----

function input()
  brush.down = btn(4)
  if btn(0) then brush.vx-=brush_acc end
  if btn(1) then brush.vx+=brush_acc end
  if btn(2) then brush.vy-=brush_acc end
  if btn(3) then brush.vy+=brush_acc end

  if paper.y==0 and btnp(5) then
    sfx(0)
    paper.y=1
    paper.vy=paper_init_vy
  end
end

----

function _init()
  memset(0x1000,0x0077,128*64)
end

function _update()
  input()
  move_brush()
  update_line_width()
end

function _draw()
  if paper.y>0 then
    replace_paper()
  else
    -- copy whole pixels in the paper to the screen
    memcpy(0x6000,0x1000,128*64)
    -- add changes made by the user to the screen
    draw_line()
    -- copy whole pixels in the screen to the paper
    memcpy(0x1000,0x6000,128*64)
  end
  draw_brush()
end
