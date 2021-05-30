--[[
协议取用json格式

查询        {"cmd":"check"}
全关        {"cmd":"allclose"}
全开        {"cmd":"allopen"}
单路控制    {"cmd":"set","id":3,"onoff":1}

硬件的状态回复

{"cmd":"status","kg":{"n":["Relay1","Relay2","Relay3","Relay4","Relay5","Relay6"],"s":[0,0,0,0,0,0]},"tempe_humid":{"n":["tempe-humid"],"t":[0],"h":[0]},"electric":{"n":["electric"],"s":[0]},"water":{"n":["water-detect"],"s":[0]}}


]]--

local xmap=require "xmap" 
local hxnet=require "hxnet" 
local sjson=require "sjson" 
local initStr="";

function module_init()
 ------注册事件
 register_event("user_use_scene");     --function user_use_scene(flag,dev,scene_name,parameter) end
 register_event("from_user");          --function user_get_scene(flag,dev,command,parameter) end
 register_event("from_mqtt_all_dev");    --function from_mqtt_all_dev(flag,dev,mqtt,topic,buf,len) end
 
 ------创建APP初始化信息
 initStr=sjson.attr(initStr,"accessType","url"); -- frm/url
 initStr=sjson.attr(initStr,"url","http://hzhsohn.github.io/hxk.fsensor/webapp.html");
 --
 initStr=sjson.attr(initStr,"debug_url","http://10.0.0.10/hxk.fsensor");
 initStr=sjson.attr(initStr,"release","true");
 initStr=sjson.attr(initStr,"test_mark","");
 
 printf("initStr="initStr);
 
 ------返回硬件标识
 return "hxk.fsensor";
end

-----------------------------------------------------------
--MSD设备处理的场景
function user_use_scene(flag,dev,scene_name,parameter)

   --全开全关
   if scene_name=="ALLON" then 
       j="{\"cmd\":\"allopen\"}";
   elseif scene_name=="ALLOFF" then
       j="{\"cmd\":\"allclose\"}";
   
   --单路控制
   elseif scene_name=="S10" then
       j="{\"cmd\":\"set\",\"id\":0,\"onoff\":0}";
   elseif scene_name=="S20" then
       j="{\"cmd\":\"set\",\"id\":1,\"onoff\":0}";
   elseif scene_name=="S30" then
       j="{\"cmd\":\"set\",\"id\":2,\"onoff\":0}";
   elseif scene_name=="S40" then
       j="{\"cmd\":\"set\",\"id\":3,\"onoff\":0}";
   elseif scene_name=="S50" then
       j="{\"cmd\":\"set\",\"id\":4,\"onoff\":0}";
   elseif scene_name=="S60" then
       j="{\"cmd\":\"set\",\"id\":5,\"onoff\":0}";
       
   elseif scene_name=="S11" then
       j="{\"cmd\":\"set\",\"id\":0,\"onoff\":1}";
   elseif scene_name=="S21" then
       j="{\"cmd\":\"set\",\"id\":1,\"onoff\":1}";
   elseif scene_name=="S31" then
       j="{\"cmd\":\"set\",\"id\":2,\"onoff\":1}";
   elseif scene_name=="S41" then
       j="{\"cmd\":\"set\",\"id\":3,\"onoff\":1}";
   elseif scene_name=="S51" then
       j="{\"cmd\":\"set\",\"id\":4,\"onoff\":1}";
   elseif scene_name=="S61" then
       j="{\"cmd\":\"set\",\"id\":5,\"onoff\":1}";
       
   end;
   
   xmap.msd_send(flag,dev,j,#j);
end

-----------------------------------------------------------
--用户发送过来的数据
function from_user(flag,dev,command,parameter)
   print("from_user--",flag,dev,command,parameter);
   if "init"==command then     
       xmap.msd_udata(flag,dev,"init", initStr,#initStr);
   elseif "state"== command then
       --print(xstr.utf8_gb2312("查询硬件状态"));
       j="{\"cmd\":\"check\"}";
       xmap.msd_send(flag,dev,j,#j)
   end
end

-----------------------------------------------------------
--MQTT网络设备的数据
function from_mqtt_all_dev(flag,dev,mqtt,topic,buf,len)         
   if("hxk.fsensor"~=flag)then
	   return 
   end

   cmd=sjson.attr_get(buf,"cmd");
   if("status"==cmd)then
        xmap.msd_udata(flag,dev,"j", buf,len);
   end
end
