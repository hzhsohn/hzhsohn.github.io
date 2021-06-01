--[[
协议取用hx-net格式
字符串标识为 KG
------->发至MCU
0x00 & ::::::::::::: 查询状态
0x01 & 循环[uchar 通道号码0~通道数量n排列的状态] ::::::::::::: 批量通道开关
0x02 & uchar 通道号码,uchar 开或关0_1 ::::::::::::: 单通道开关控制
------->返回至控制端
0x10 & 循环[uchar 通道号码0~n的状态] ::::::::::::: 通道状态

--开关字节格式
0x01-0x64 代表亮度百分比
0xA0-0xAF 代表点控模式,0x10=通断1毫秒 ,0x11=100毫秒,0x12=200毫秒...0x1F=1.5秒


]]--

local xmap=require "xmap" 
local hxnet=require "hxnet" 
local sjson=require "sjson" 
local xstr=require "xstring" 
local initStr="";
local pubmem=require "pubmem" 

function module_init()
  ------注册事件
  register_event("user_use_scene");       --function user_use_scene(flag,dev,scene_name,parameter) end
  register_event("from_user");            --function user_get_scene(flag,dev,command,parameter) end
  register_event("from_mqtt_all_dev");    --function from_mqtt_all_dev(flag,dev,mqtt,topic,buf,len) end
  
  ------创建APP初始化信息
  initStr=sjson.attr(initStr,"accessType","url"); -- frm/url
  --
  initStr=sjson.attr(initStr,"url","https://hzhsohn.github.io/KG4.msdc");
  --
  initStr=sjson.array(initStr, "frm", "title:ti::四路通断控制器");
  initStr=sjson.array(initStr, "frm", "button::aon::全开::ALLON#"); --按键
  initStr=sjson.array(initStr, "frm", "button::aoff::全关::ALLOFF#");
  initStr=sjson.array(initStr, "frm", "switch::b1::通断1::S10#::S11#"); --开关
  initStr=sjson.array(initStr, "frm", "switch::b2::通断2::S20#::S21#");
  initStr=sjson.array(initStr, "frm", "switch::b3::通断3::S30#::S31#");
  initStr=sjson.array(initStr, "frm", "switch::b4::通断4::S40#::S41#");

  printf("devflag->KG4 initStr=%s",initStr);     
  return "KG4";
end

------------------------------------------------------------
--MSD设备处理的场景
function user_use_scene(flag,dev,scene_name,parameter)
    --print("KG4 user_use_scene="..scene_name,parameter);
    if scene_name=="ALLON" then 
        print(xstr.utf8_gb2312("全开"));
        da,dalen=hxnet.create("KG",string.char(0x01,1,1,1,1),5);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    elseif scene_name=="ALLOFF" then
        print(xstr.utf8_gb2312("全关"));
        da,dalen=hxnet.create("KG",string.char(0x01,0,0,0,0),5);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    
    --单路控制
    elseif scene_name=="S11" then
        da,dalen=hxnet.create("KG",string.char(0x02,0,1),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    elseif scene_name=="S10" then
        da,dalen=hxnet.create("KG",string.char(0x02,0,0),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);

    elseif scene_name=="S21" then
        da,dalen=hxnet.create("KG",string.char(0x02,1,1),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    elseif scene_name=="S20" then
        da,dalen=hxnet.create("KG",string.char(0x02,1,0),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
   
    elseif scene_name=="S31" then
        da,dalen=hxnet.create("KG",string.char(0x02,2,1),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    elseif scene_name=="S30" then
        da,dalen=hxnet.create("KG",string.char(0x02,2,0),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
        
    elseif scene_name=="S41" then
        da,dalen=hxnet.create("KG",string.char(0x02,3,1),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    elseif scene_name=="S40" then
        da,dalen=hxnet.create("KG",string.char(0x02,3,0),3);
        bf,le=xstr.hex2json(da,dalen);
        xmap.msd_send(flag,dev,bf,le);
    else
        print(xstr.utf8_gb2312("执行了未知场景->"),flag,dev,scene_name,parameter);
    end;
end

------------------------------------------------------------
--用户发送过来的数据
function from_user(flag,dev,command,parameter)    

    --print("from_user--",flag,dev,command,parameter);
    
    --初始化加载
    if "init"==command then    
       xmap.msd_udata(flag,dev,"init", initStr,#initStr);   

    --查询硬件状态
    elseif "state"== command then         
        bf,le=hxnet.create("KG",string.char(0x00),1);
        xmap.msd_send(flag,dev,bf,le);
    end
    
end

------------------------------------------------------------
--MSD设备的数据
function from_mqtt_all_dev(flag,dev,mqtt,topic,buf,len)    
     
    if("KG4"~=flag) then
        return;
    end

    --解出单片机数据
    --print("-from_mqtt=",flag,dev,mqtt,topic,buf,len);
    msdbuf,msdlen=xstr.json2hex(buf,len);
    if(null==msdbuf)then
      return
    end
      
    prol_flag,param,param_len=hxnet.getframe(msdbuf,msdlen);
    if(null==prol_flag)then
      return
    end

    --判断是否为 KG协议
    if prol_flag=="KG" then
        if string.byte(param,1)==0x10 then
             --存入公共内存
             pubmem.set(flag.."-"..dev.."-".."b1",string.byte(param,2));
             pubmem.set(flag.."-"..dev.."-".."b2",string.byte(param,3));
             pubmem.set(flag.."-"..dev.."-".."b3",string.byte(param,4));
             pubmem.set(flag.."-"..dev.."-".."b4",string.byte(param,5));             
             --printf(pubmem.show());
             
             --回复到app
             sj= string.format("[{\"b1\":\"%d\"},{\"b2\":\"%d\"},{\"b3\":\"%d\"},{\"b4\":\"%d\"}]",
                                string.byte(param,2),string.byte(param,3),string.byte(param,4),string.byte(param,5))
             xmap.msd_udata(flag,dev,"j",sj);
             --printf(sj);
         end
    end
    
end

