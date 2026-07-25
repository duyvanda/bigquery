CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_update_tinhhinh_sp_canhtranh_thau()
BEGIN 
  TRUNCATE TABLE staging_temp.f_update_tinhhinh_sp_canhtranh_thau_temp;

 INSERT INTO staging_temp.f_update_tinhhinh_sp_canhtranh_thau_temp(


-- Create table staging_temp.f_update_tinhhinh_sp_canhtranh_thau_temp
-- as

with clean_data as (
select 
replace (trim(upper(tenthuoc))," ","") as tenthuoc,
replace(replace (trim(lower(ndhl))," ",""),'.',',') as ndhl,
replace(replace (trim(lower(quycachdonggoi))," ",""),'.',',') as quycachdonggoi,
replace (trim(lower(dangbaoche))," ","") as dangbaoche,
trim(lower(tenhoatchatthanhphanduoclieu)) as ten_hoatchat,
replace (trim(lower(sdkgpnk))," ","") as sdkgpnk,
replace (trim(lower(nhathautrungthau))," ","") as nhathautrungthau,
replace (trim(upper(nuocsanxuat))," ","") as nuocsanxuat,
replace (trim(upper(tencososanxuat))," ","") as tencososanxuat,
nhathautrungthau as nhathautrungthau_ori,
Case when right(nhomthuoc,1) = '1' then '1' 
        when right(nhomthuoc,1) ='2' then '2' 
        when right(nhomthuoc,1) ='3' then '3' 
        when right(nhomthuoc,1) ='4' then '4' 
        when right(nhomthuoc,1) ='5' then '5' 
        when nhomthuoc like '%Biệt%' or nhomthuoc like '%dược%' then 'BDG'
        else nhomthuoc end as nhomthuoc,
dongiavnd,
nuocsanxuat as nuocsanxuat_ori,
ndhl as ndhl_ori,
tenthuoc as tenthuoc_ori,
tenhoatchatthanhphanduoclieu as ten_hoatchat_ori,
replace (trim(lower(tenhoatchatthanhphanduoclieu))," ","") as xoa_blank,

trim(regexp_replace((regexp_replace( replace(ngayqdtrungthau,'-','/'),r'([^0-9/])','')),"\n",''))  as ngayqdtrungthau,
Case 
    when ngayqdtrungthau like '%/%'  then LENGTH(ngayqdtrungthau) - LENGTH(REGEXP_REPLACE(ngayqdtrungthau, '/', ''))
    when ngayqdtrungthau like '%-%'  then LENGTH(ngayqdtrungthau) - LENGTH(REGEXP_REPLACE(ngayqdtrungthau, '-', ''))
    else 0 end as chua_dauso,
    fromdate,
    todate
-- replace( replace (trim(lower(tenhoatchatthanhphanduoclieu))," ",""),"-","") as xoa_blank

 from `staging.d_manual_danh_sach_trungthau_cql_duoc`
)
,
/*    Tổng cộng kết hợp dc 27 hoạt chất
hoạt chất 1                                      hoạt chất 2                  hoạt chất 3
-- cefixim
-- cefuroxim
-- chlorhexidindigluconat
-- azelastinhydroclorid                          fluticasonepropionat  
-- omeprazol
-- hydroxydpolymaltose                           acidfolic or folicacid       pyridoxinhcl or pyridoxinehydrochlorid
-- sodiumalginate or sodiumalginat               calciumcarbonat              sodiumbicarbonat
-- polysaccharide or polysaccharid
-- acidacetic  or ceticacid
-- cefaclor
-- cefpodoxim
-- tobramycin                                   dexamethasone
-- fluorometholon
-- hydroxypropylmethylcellulose
-- olopatadin
-- budesonid
-- fluticasonepropionat
-- clobetasolpropionat
-- fusidicacid   or acidfusidic                 hydrocortisonacetat   
-- natrihyaluronat
-- rifamycin
-- magnesihydroxyd                              nhômhydroxyd
-- magnesihydroxyd                              nhômhydroxyd                   simethicon
-- neomycinsulfat                               polymyxinbsulfat               dexamethasone
-- neomycin                                     polymyxinb                     dexamethasone
-- miconazole
-- mometasonefuroat
*/

loc_data_chua_hoatchat as (
select  
*except(xoa_blank),
case when xoa_blank like '%;' or xoa_blank like '%,' or xoa_blank like '%+' or xoa_blank like '%.' then 
  substr(xoa_blank,0,length(xoa_blank)-1)
  else xoa_blank end as xoa_blank,

Case 
      when (xoa_blank like '%hydroxydpolymaltose%' or  xoa_blank like '%Sắt%')  and (xoa_blank like '%acidfolic%' or xoa_blank like '%folicacid%')
                                                  and (xoa_blank like '%pyridoxinhcl%'  or xoa_blank like '%pyridoxinehydrochlorid%' or xoa_blank like '%pyridoxin%')   then 3  

      when (xoa_blank like '%sodiumalginat%' or xoa_blank like '%sodium%') and (xoa_blank like '%calciumcarbonat%' or xoa_blank like '%calcium%') 
                      and  ( xoa_blank like '%sodiumbicarbonat%' or xoa_blank like '%sodium%') then 3.1

      when (xoa_blank like '%magnesihydroxyd%' or xoa_blank like '%magnesi%') and ( xoa_blank like '%nhômhydroxyd%' or xoa_blank like '%nhôm%') and xoa_blank like '%simethicon%' then 3.2

      when xoa_blank like '%neomycin%'  and xoa_blank like '%polymyxin%' and xoa_blank like '%dexamethason%' and ndhl like '%60,000iu%'  then 3.3

      when xoa_blank like '%neomycin%' and xoa_blank like '%polymyxin%' and xoa_blank like '%dexamethasone%' and ndhl like '%100,000iu%' then 3.4  

      when (xoa_blank like '%azelastinhydroclorid%' or xoa_blank like '%azelastin%') and (xoa_blank like '%fluticasonepropionat%' or xoa_blank like '%fluticason%') then 2  
    
      when xoa_blank like '%tobramycin%' and xoa_blank like '%dexamethason%' then 2.1 
    
      when (xoa_blank like '%fusidicacid%' or xoa_blank like '%acidfusidic%') and xoa_blank like '%hydrocortisonacetat%' then 2.2

      when (xoa_blank like '%magnesihydroxyd%' or xoa_blank like '%magnesi%') and  ( xoa_blank like '%nhômhydroxyd%' or xoa_blank like '%nhôm%') then 2.3


      when xoa_blank like '%cefixim%' then 1 

      when xoa_blank like '%cefuroxim%' then 1.01  
      when xoa_blank like '%chlorhexidindigluconat%' or xoa_blank like '%chlorhexidin%' then 1.02

      when xoa_blank like '%omeprazol%'  then 1.03  --esomeprazol


      when xoa_blank like '%polysaccharid%' then 1.04  
      when xoa_blank like '%acidacetic%' or xoa_blank like '%ceticacid%' then 1.05  

      when xoa_blank like '%cefaclor%' then 1.06  
      when xoa_blank like '%cefpodoxim%' then 1.07   --cefpodoximproxetil

      when xoa_blank like '%fluorometholon%' then 1.08  

      when xoa_blank like '%hydroxypropylmethylcellulose%' then 1.09  
      when xoa_blank like '%olopatadin%' then 1.1   --olopatadinhydroclorid

      when xoa_blank like '%budesonid%' then 1.11  
      when xoa_blank like '%fluticasonepropionat%' or xoa_blank like '%fluticason%' then 1.12 

      when xoa_blank like '%clobetasolpropionat%' or xoa_blank like '%clobetasol%'  then 1.13 

      when xoa_blank like '%natrihyaluronat%' or xoa_blank like '%hyaluronatnatri%' then 1.14  
      when xoa_blank like '%rifamycin%' then 1.15 

      when xoa_blank like '%miconazole%' or xoa_blank like '%miconazol%' then 1.16
      when xoa_blank like '%mometasonefuroat%' or xoa_blank like '%mometason%' then 1.17 


else 0

 end as chua_hoatchat,

Case when chua_dauso < 2 then '01' else
split(ngayqdtrungthau,'/')[OFFSET(0)] end as  part1,

Case when chua_dauso < 2 then '01' else
split(ngayqdtrungthau,'/')[OFFSET(1)] end as  part2,

Case when chua_dauso < 2 then '2022' else
left(split(ngayqdtrungthau,'/')[OFFSET(2)],4) end as  part3
    from clean_data

),

loc_data_chua_hoatchat_0 as 
(
select *except(xoa_blank),
-- xoa_blank as xoa_blank_ori,
Case when xoa_blank like '%-%' and chua_hoatchat >0 then LENGTH(xoa_blank) - LENGTH(REGEXP_REPLACE(xoa_blank, '-', ''))   else 0 end as chua_dau_gachngang,
Case when xoa_blank like '%-%' and chua_hoatchat >0 then replace( xoa_blank,"-","+")
     when xoa_blank like '%và%' and chua_hoatchat >0 then replace( xoa_blank,"và","+")
else xoa_blank end as xoa_blank,

  Case when Cast (part3 as int64) > cast(left(todate,4) as int) then date (cast(left(todate,4) as int),Cast (part2 as int64) ,Cast (part1 as int64) )
  else
  date ( cast(part3 as int64),Cast (part2 as int64) ,Cast (part1 as int64) ) end as ngayqd_trungthau_clean
 from loc_data_chua_hoatchat
),

loc_data_chua_hoatchat_1 as(
select *,

  STRPOS(xoa_blank , '(') AS first_,
    STRPOS(xoa_blank , ')') AS last_,
 LENGTH(xoa_blank) - LENGTH(Replace(xoa_blank, '+', '')) as chua_daucong,
 LENGTH(xoa_blank) - LENGTH(Replace(xoa_blank, ',', '')) as chua_dauphay,
 LENGTH(xoa_blank) - LENGTH(Replace(xoa_blank, ';', '')) as chua_dau_champhay,
 (Case 
        when xoa_blank like '%(%' and xoa_blank like '%)%'  then 
          length(
            regexp_replace(
            concat (  replace (xoa_blank, substr(xoa_blank,STRPOS(xoa_blank , '('),STRPOS(xoa_blank , ')')),'') , 
                      substr(xoa_blank,STRPOS(xoa_blank , ')')+1 )
                      )
                      , r"([0-9,])","")
               ) 
        else length(regexp_replace(xoa_blank,r"([0-9,])","")) 
            end )

               - 
              
              ( Case 
                    when chua_hoatchat = 1 then length('cefixim')
                    when chua_hoatchat = 1.01 then length('cefuroxim')
                    when chua_hoatchat = 1.02 then length('chlorhexidindigluconat')
                    when chua_hoatchat = 1.03 then length('omeprazol')
                    when chua_hoatchat = 1.04 then length('polysaccharid')
                    when chua_hoatchat = 1.05 then length('acidacetic') 
                    when chua_hoatchat = 1.06 then length('cefaclor')
                    when chua_hoatchat = 1.07 then length('cefpodoxim')                    
                    when chua_hoatchat = 1.08 then length('fluorometholon')
                    when chua_hoatchat = 1.09 then length('hydroxypropylmethylcellulose')
                    when chua_hoatchat = 1.1 then length('olopatadin')                    
                    when chua_hoatchat = 1.11 then length('budesonid')
                    when chua_hoatchat = 1.12 then length('fluticasonepropionat') 
                    when chua_hoatchat = 1.13 then length('clobetasolpropionat')
                    when chua_hoatchat = 1.14 then length('natrihyaluronat')
                    when chua_hoatchat = 1.15 then length('rifamycin')
                    when chua_hoatchat = 1.16 then length('miconazole')
                    when chua_hoatchat = 1.17 then length('mometasonefuroat')
                    else 0 end ) 
                    
                    as do_dai,


   
 from loc_data_chua_hoatchat_0  ) ,

--------------Lấy ra các thuốc có 3 hoạt chất

data_hoatchat_result as (
 select *,
  from loc_data_chua_hoatchat_1 where chua_hoatchat >=3 and chua_daucong +chua_dauphay+chua_dau_champhay >=3 and chua_daucong +chua_dauphay+chua_dau_champhay < 9 and (chua_daucong =2 or chua_dau_champhay =2 )
UNION ALL
 select *
  from loc_data_chua_hoatchat_1 where chua_hoatchat >=3 and chua_daucong +chua_dauphay+chua_dau_champhay <3 

--------------Lấy ra các thuốc có 2 hoạt chất
UNION ALL
  select * from loc_data_chua_hoatchat_1 where chua_hoatchat >=2 and chua_hoatchat <3 and  chua_daucong +chua_dauphay+chua_dau_champhay <2


--------------Lấy ra các thuốc có 1 hoạt chất
UNION ALL
  select * from loc_data_chua_hoatchat_1 
  where chua_hoatchat >=1 and chua_hoatchat <2   and do_dai <=0
UNION ALL
  select * from loc_data_chua_hoatchat_1 
  where chua_hoatchat >=1 and chua_hoatchat <2   and do_dai >0 and chua_daucong +chua_dauphay+chua_dau_champhay =0
UNION ALL
  select * from loc_data_chua_hoatchat_1 
  where chua_hoatchat >=1 and chua_hoatchat <2   and do_dai >0 and chua_daucong +chua_dauphay+chua_dau_champhay >0 and chua_dauphay <=3 and chua_daucong+chua_dau_champhay=0 and do_dai <18


  
),


data_hoatchat_result1 as 

(

  select *,
  Case when chua_hoatchat >=3 and chua_daucong +chua_dauphay+chua_dau_champhay >=3 and chua_daucong +chua_dauphay+chua_dau_champhay < 9 and (chua_daucong =2 or chua_dau_champhay =2 ) then 'Trùng hoạt chất'
      when chua_hoatchat >=3 and chua_daucong +chua_dauphay+chua_dau_champhay <3  then 'Trùng hoạt chất'
      when chua_hoatchat >=2 and chua_hoatchat <3 and  chua_daucong +chua_dauphay+chua_dau_champhay <2 then 'Trùng hoạt chất'
      when chua_hoatchat >=1 and chua_hoatchat <2   and do_dai <=0 then 'Trùng hoạt chất'
      when chua_hoatchat >=1 and chua_hoatchat <2   and do_dai >0 and chua_daucong +chua_dauphay+chua_dau_champhay =0 then 'Trùng hoạt chất'
      when chua_hoatchat >=1 and chua_hoatchat <2   and do_dai >0 and chua_daucong +chua_dauphay+chua_dau_champhay >0 and chua_dauphay <=3 and chua_daucong+chua_dau_champhay=0 and do_dai <18 then 'Trùng hoạt chất'

      else 'Không trùng hoạt chất' end as loc_hoatchat
  
   from loc_data_chua_hoatchat_1
),



result as (
select *,
Case 
                    when chua_hoatchat =1 and ndhl like '%50mg%' and ndhl not like '%150mg%' then 1
                    when chua_hoatchat =1 and ndhl like '%75mg%' then 2
                    when chua_hoatchat =1 and ndhl like '%150mg%' then 3
                    when chua_hoatchat =1 and ndhl like '%200mg%' then 4
                    when chua_hoatchat =1 and ndhl like '%250mg%' then 5
                    when chua_hoatchat = 1.01  and ndhl like '%500mg%' then 6
                    when chua_hoatchat = 1.01 and ndhl like '%125mg%' then 7
                    when chua_hoatchat = 1.01 and ndhl like '%250mg%' then 8
                    when chua_hoatchat = 1.02 and ndhl like '%0,5g%' then 9
                    when chua_hoatchat = 1.03 and ndhl like '%20mg%' then 10
                    when chua_hoatchat = 1.04 and ndhl like '%340,91mg%' then 11
                    when chua_hoatchat = 1.05 and ndhl like '%2\\%%'  and ndhl not like '%,2\\%%' then 12
                    when chua_hoatchat = 1.06 and ndhl like '%375mg%' then 13
                    -- when chua_hoatchat = 1.07 and ndhl like '%100mg%'  then 14
                    when chua_hoatchat = 1.07 and ndhl like '%200mg%' then 15
                    when chua_hoatchat = 1.07 and ndhl like '%50mg%' then 16
                    when chua_hoatchat = 1.07 and ndhl like '%100mg%' then 17           
                    when chua_hoatchat = 1.08 and ndhl like '%1mg%' then 18   
                    when chua_hoatchat = 1.09 and ndhl like '%45mg%' then 19
                    when chua_hoatchat = 1.1 and ndhl like '%2mg%' then 20              
                    when chua_hoatchat = 1.11 and ndhl like '%64mcg%' then 21   
                    when chua_hoatchat = 1.12 and ndhl like '%50mcg%' then 22   
                    when chua_hoatchat = 1.13 and ndhl like '%0,05\\%%' then 23  
                    when chua_hoatchat = 1.14 and ndhl like '%21,6mg%' then 24 
                    when chua_hoatchat = 1.15 and (ndhl like '%200,000iu%' or ndhl like '%200000iu%') then 25 
                    when chua_hoatchat = 1.16 and ndhl like '%2\\%%'  and ndhl not like '%,2\\%%' then 26
                    when chua_hoatchat = 1.17 and ndhl like '%50mcg%' and quycachdonggoi like '%60liều%' then 27  
                    when chua_hoatchat = 1.17 and ndhl like '%50mcg%'  and quycachdonggoi like '%120liều%' then 28
                    when chua_hoatchat = 2 and ndhl like '%0,137mg%' and ndhl like '%0,05mg%' then 29              
                    when chua_hoatchat = 2.1 and ndhl like '%15mg%' and ndhl like '%5mg%' and ( LENGTH(ndhl) - LENGTH(Replace(ndhl, '5mg', '')) )=6 then 30   --trùng 5mg k like dc
                    when chua_hoatchat = 2.2 and ndhl like '%100mg%' and ndhl like '%50mg%'  then 31   
                    when chua_hoatchat = 2.3 and ndhl like '%390mg%'  and ndhl like '%336,6mg%'  then 32  
                    when chua_hoatchat = 3 and ndhl like '%178,5mg%' and ndhl like '%0,175mg%'  and ndhl like '%16mg%'  then 33
                    when chua_hoatchat = 3.1 and ndhl like '%500mg%' and ndhl like '%160mg%'  and ndhl like '%267mg%'  then 34
                    when chua_hoatchat = 3.2 and ndhl like '%400mg%' and ndhl like '%351,9mg%'  and ndhl like '%50mg%'  then 35 
                    when chua_hoatchat = 3.3 and ( ndhl like '%35,000iu%' or ndhl like '%35000iu%') and ( ndhl like '%60,000iu%' or ndhl like '%60000iu%')  and ndhl like '%10mg%'  then 36
                    when chua_hoatchat = 3.4 and ndhl like '%35mg%' and ( ndhl like '%10,000iu%' or ndhl like '%10000iu%')  and ndhl like '%10mg%'  then 37
    
else 0 end as phanloai_ndhl,

Case 
                    when chua_hoatchat = 1 and loc_hoatchat <>'Không trùng hoạt chất' then 'Cefixim'
                    when chua_hoatchat = 1.01  and loc_hoatchat <>'Không trùng hoạt chất' then 'Cefuroxim'
                    when chua_hoatchat = 1.02  and loc_hoatchat <>'Không trùng hoạt chất' then 'Chlorhexidindigluconat'
                    when chua_hoatchat = 1.03  and loc_hoatchat <>'Không trùng hoạt chất' then 'Omeprazol'
                    when chua_hoatchat = 1.04  and loc_hoatchat <>'Không trùng hoạt chất' then 'Polysaccharid'
                    when chua_hoatchat = 1.05  and loc_hoatchat <>'Không trùng hoạt chất' then 'Acidacetic'
                    when chua_hoatchat = 1.06  and loc_hoatchat <>'Không trùng hoạt chất' then 'Cefaclor'
                    when chua_hoatchat = 1.07  and loc_hoatchat <>'Không trùng hoạt chất' then 'Cefpodoxim'                   
                    when chua_hoatchat = 1.08  and loc_hoatchat <>'Không trùng hoạt chất' then 'Fluorometholon'
                    when chua_hoatchat = 1.09  and loc_hoatchat <>'Không trùng hoạt chất' then 'Hydroxypropyl methylcellulose'
                    when chua_hoatchat = 1.1  and loc_hoatchat <>'Không trùng hoạt chất' then 'Olopatadin'                   
                    when chua_hoatchat = 1.11  and loc_hoatchat <>'Không trùng hoạt chất' then 'Budesonid'
                    when chua_hoatchat = 1.12  and loc_hoatchat <>'Không trùng hoạt chất' then 'Fluticasone propionat'
                    when chua_hoatchat = 1.13  and loc_hoatchat <>'Không trùng hoạt chất' then 'Clobetasol propionat'
                    when chua_hoatchat = 1.14  and loc_hoatchat <>'Không trùng hoạt chất' then 'Natrihyaluronat'
                    when chua_hoatchat = 1.15  and loc_hoatchat <>'Không trùng hoạt chất' then 'Rifamycin'
                    when chua_hoatchat = 1.16  and loc_hoatchat <>'Không trùng hoạt chất' then 'Miconazole'
                    when chua_hoatchat = 1.17  and loc_hoatchat <>'Không trùng hoạt chất' then 'Mometasone furoat'
                    when chua_hoatchat = 2  and loc_hoatchat <>'Không trùng hoạt chất' then 'Azelastin hydroclorid + fluticasone propionat'
                    when chua_hoatchat = 2.1  and loc_hoatchat <>'Không trùng hoạt chất' then 'Tobramycin + dexamethasone'
                    when chua_hoatchat = 2.2  and loc_hoatchat <>'Không trùng hoạt chất' then 'Fusidic acid + hydrocortison acetat'
                    when chua_hoatchat = 2.3  and loc_hoatchat <>'Không trùng hoạt chất' then 'Magnesi hydroxyd + nhôm hydroxyd'
                    when chua_hoatchat = 3  and loc_hoatchat <>'Không trùng hoạt chất' then 'Hydroxyd polymaltose + acid folic + pyridoxin hcl'
                    when chua_hoatchat = 3.1  and loc_hoatchat <>'Không trùng hoạt chất' then 'Hodium alginate + calcium carbonate + sodium bicarbonate'
                    when chua_hoatchat = 3.2  and loc_hoatchat <>'Không trùng hoạt chất' then 'Hagnesi hydroxyd + nhôm hydroxyd + simethicon'
                    when chua_hoatchat = 3.3  and loc_hoatchat <>'Không trùng hoạt chất' then 'Neomycin + polymyxin + dexamethason'
                    when chua_hoatchat = 3.4  and loc_hoatchat <>'Không trùng hoạt chất' then 'Neomycin + polymyxin + dexamethason'
                    else ten_hoatchat_ori end as hoat_chat_clean,

Case 
                    when chua_hoatchat =1 and ndhl like '%50mg%' and ndhl not like '%150mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then 'MECEFIX-B.E 50MG'
                    when chua_hoatchat =1 and ndhl like '%75mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then 'MECEFIX-B.E 75MG'
                    when chua_hoatchat =1 and ndhl like '%150mg%' and dangbaoche like '%viên%'  then 'MECEFIX-B.E 150MG'
                    when chua_hoatchat =1 and ndhl like '%200mg%' and dangbaoche like '%viên%'  then 'MECEFIX-B.E 200MG'
                    when chua_hoatchat =1 and ndhl like '%250mg%' and dangbaoche like '%viên%'  then 'MECEFIX-B.E 250MG'
                     when chua_hoatchat =1 then 'MECEFIX-B.E'
                    when chua_hoatchat = 1.01  and ndhl like '%500mg%' and dangbaoche like '%viên%' then 'EFODYL'
                    when chua_hoatchat = 1.01 and ndhl like '%125mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then 'EFODYL'
                    when chua_hoatchat = 1.01 and ndhl like '%250mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then 'EFODYL'
                     when chua_hoatchat = 1.01 then 'EFODYL'
                    when chua_hoatchat = 1.02 and ndhl like '%250ml%' and dangbaoche like '%thuốctácdụngtạiniêmmạcmiệng%' then 'MEDORAL'  
                     when chua_hoatchat = 1.02  then 'MEDORAL' 
                    when chua_hoatchat = 1.03 and ndhl like '%20mg%'  and dangbaoche like '%viên%'  then 'STOMEX'
                    when chua_hoatchat = 1.03 then 'STOMEX'
                    when chua_hoatchat = 1.04 and ndhl like '%340,91mg%' and dangbaoche like '%viên%'  then 'FERRITOX'
                     when chua_hoatchat = 1.04  then 'FERRITOX'
                    when chua_hoatchat = 1.05 and ndhl like '%2\\%%'  and ndhl not like '%,2\\%%' and dangbaoche like '%thuốcnhỏtai%'  then 'MEPATYL' 
                    when chua_hoatchat = 1.05 then 'MEPATYL' 
                    when chua_hoatchat = 1.06 and ndhl like '%375mg%'and dangbaoche like '%viên%'  then 'METINY'
                     when chua_hoatchat = 1.06 then 'METINY'
                    when chua_hoatchat = 1.07 and ndhl like '%100mg%'and dangbaoche like '%viên%'  then 'CEBEST'
                    when chua_hoatchat = 1.07 and ndhl like '%200mg%'and dangbaoche like '%viên%'  then 'CEBEST'
                    when chua_hoatchat = 1.07 and ndhl like '%50mg%'and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%'  then 'CEBEST'
                    when chua_hoatchat = 1.07 and ndhl like '%100mg%'and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%'  then 'CEBEST'  
                      when chua_hoatchat = 1.07   then 'CEBEST'  
                    when chua_hoatchat = 1.08 and ndhl like '%1ml%' and ndhl like '%1mg%' and dangbaoche like '%thuốcnhỏmắt%'  then 'NAVALDO' 
                    when chua_hoatchat = 1.08 then 'NAVALDO' 
                    when chua_hoatchat = 1.09 and ndhl like '%15ml%'and ndhl like '%45mg%' and dangbaoche like '%thuốcnhỏmắt%'  then 'SYSEYE' 
                    when chua_hoatchat = 1.09  then 'SYSEYE'
                    when chua_hoatchat = 1.1 and ndhl like '%1ml%' and ndhl like '%2mg%' and dangbaoche like '%thuốcnhỏmắt%'  then 'OLEVID'  
                      when chua_hoatchat = 1.1 then 'OLEVID'  
                    when chua_hoatchat = 1.11 and ndhl like '%64mcg%' and dangbaoche like '%thuốcxịtmũi%'  then 'BENITA'   
                       when chua_hoatchat = 1.11  then 'BENITA'  
                    when chua_hoatchat = 1.12 and ndhl like '%50mcg%' and dangbaoche like '%thuốcxịtmũi%'  then 'MESECA' 
                      when chua_hoatchat = 1.12 then 'MESECA' 
                    when chua_hoatchat = 1.13 and ndhl like '%0,05\\%%'and dangbaoche like '%thuốcdùngngoài%'  then 'BENATE FORT OINTMENT'   
                     when chua_hoatchat = 1.13  then 'BENATE FORT OINTMENT' 
                    when chua_hoatchat = 1.14 and ndhl like '%12ml%' and ndhl like '%21,6mg%'  and dangbaoche like '%thuốcnhỏmắt%'  then 'VITOL'   
                    when chua_hoatchat = 1.14  then 'VITOL'
                    when chua_hoatchat = 1.15 and (ndhl like '%200,000iu%' or ndhl like '%200000iu%')  and dangbaoche like '%thuốcnhỏtai%'  then 'METOXA'  
                    when chua_hoatchat = 1.15 then 'METOXA'
                    when chua_hoatchat = 1.16 and ndhl like '%2\\%%'  and ndhl not like '%,2\\%%'  and dangbaoche like '%thuốctácdụngtạiniêmmạcmiệng%'  then 'VADIKIDDY'   
                    when chua_hoatchat = 1.16 then 'VADIKIDDY'  

                    when chua_hoatchat = 1.17 and ndhl like '%50mcg%' and quycachdonggoi like '%60liều%' and dangbaoche like '%thuốcxịtmũi%'  then 'ADACAST'    
                    when chua_hoatchat = 1.17 and ndhl like '%50mcg%'  and quycachdonggoi like '%120liều%'and dangbaoche like '%thuốcxịtmũi%'  then 'ADACAST'  
                    when chua_hoatchat = 1.17   then 'ADACAST' 
                    when chua_hoatchat = 2 and ndhl like '%0,137mg%' and ndhl like '%0,05mg%' and dangbaoche like '%thuốcxịtmũi%'  then 'MESECA FORT'   
                      when chua_hoatchat = 2       then 'MESECA FORT'    
                    when chua_hoatchat = 2.1 and ndhl like '%15mg%' and ndhl like '%5mg%' and ( LENGTH(ndhl) - LENGTH(Replace(ndhl, '5mg', '')) )=6 and ndhl like '%5ml%' and dangbaoche like '%thuốcnhỏmắt%'  then 'METODEX SPS' 
                    when chua_hoatchat = 2.1 then 'METODEX SPS' 
                    when chua_hoatchat = 2.2 and ndhl like '%100mg%' and ndhl like '%50mg%'  and dangbaoche like '%thuốcdùngngoài%'  then 'VEDANAL FORT' 
                    when chua_hoatchat = 2.2 then 'VEDANAL FORT'
                    when chua_hoatchat = 2.3 and ndhl like '%390mg%'  and ndhl like '%336,6mg%' 
                              and dangbaoche like '%dungdịch%' and  dangbaoche like '%hỗndịch%'and  dangbaoche like '%nhũdịchuống%' then 'AMFORTGEL' 
                    when chua_hoatchat = 2.3   then 'AMFORTGEL'
                    when chua_hoatchat = 3 and ndhl like '%178,5mg%' and ndhl like '%0,175mg%'  and ndhl like '%1mg%'  and dangbaoche like '%viên%' then 'FIORA'
                    when chua_hoatchat = 3 then 'FIORA'
                    when chua_hoatchat = 3.1 and ndhl like '%500mg%' and ndhl like '%160mg%'  and ndhl like '%267mg%'
                               and dangbaoche like '%dungdịch%' and  dangbaoche like '%hỗndịch%'and  dangbaoche like '%nhũdịchuống%' then 'EBYSTA'
                    when chua_hoatchat = 3.1  then 'EBYSTA'      

                    when chua_hoatchat = 3.2 and ndhl like '%400mg%' and ndhl like '%351,9mg%'  and ndhl like '%50mg%'  
                               and dangbaoche like '%dungdịch%' and  dangbaoche like '%hỗndịch%'and  dangbaoche like '%nhũdịchuống%' then 'AQUIMA' 
                     when chua_hoatchat = 3.2    then 'AQUIMA'      
                    when chua_hoatchat = 3.3 and ( ndhl like '%35,000iu%' or ndhl like '%35000iu%') and ( ndhl like '%60,000iu%' or ndhl like '%60000iu%')  and ndhl like '%10mg%'
                               and dangbaoche like '%thuốcnhỏmắt%'  then 'SCOFI' 
                    when chua_hoatchat = 3.3  then 'SCOFI' 
                    when chua_hoatchat = 3.4 and ndhl like '%35mg%' and ( ndhl like '%10,000iu%' or ndhl like '%10000iu%')  and ndhl like '%10mg%'  
                               and dangbaoche like '%thuốcnhỏtai%'  then 'MEPOLY'  
                     when chua_hoatchat = 3.4  then 'MEPOLY'  
    
else null end as phanloai_thuoc,

Case 
                    when chua_hoatchat =1 and ndhl like '%50mg%' and ndhl not like '%150mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then '50MG'
                    when chua_hoatchat =1 and ndhl like '%75mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then '75MG'
                    when chua_hoatchat =1 and ndhl like '%150mg%' and dangbaoche like '%viên%'  then '150MG'
                    when chua_hoatchat =1 and ndhl like '%200mg%' and dangbaoche like '%viên%'  then '200MG'
                    when chua_hoatchat =1 and ndhl like '%250mg%' and dangbaoche like '%viên%'  then '250MG'
                    when chua_hoatchat = 1.01  and ndhl like '%500mg%' and dangbaoche like '%viên%' then '500MG'
                    when chua_hoatchat = 1.01 and ndhl like '%125mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then '125MG'
                    when chua_hoatchat = 1.01 and ndhl like '%250mg%' and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%' then '250MG'
                    when chua_hoatchat = 1.02 and ndhl like '%250ml%' and dangbaoche like '%thuốctácdụngtạiniêmmạcmiệng%' then '250ML'  
                    when chua_hoatchat = 1.03 and ndhl like '%20mg%'  and dangbaoche like '%viên%'  then '20MG'
                    when chua_hoatchat = 1.04 and ndhl like '%340,91mg%' and dangbaoche like '%viên%'  then '340,91MG'
                    when chua_hoatchat = 1.05 and ndhl like '%2\\%%'  and ndhl not like '%,2\\%%' and dangbaoche like '%thuốcnhỏtai%'  then '2%' 
                    when chua_hoatchat = 1.06 and ndhl like '%375mg%'and dangbaoche like '%viên%'  then '375MG'
                    when chua_hoatchat = 1.07 and ndhl like '%100mg%'and dangbaoche like '%viên%'  then '100MG'
                    when chua_hoatchat = 1.07 and ndhl like '%200mg%'and dangbaoche like '%viên%'  then '200MG'
                    when chua_hoatchat = 1.07 and ndhl like '%50mg%'and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%'  then '50MG'
                    when chua_hoatchat = 1.07 and ndhl like '%100mg%'and dangbaoche like '%bột%' and dangbaoche like '%cốm%' and dangbaoche like '%hạtphauống%'  then '100MG'     
                    when chua_hoatchat = 1.08 and ndhl like '%1ml%' and ndhl like '%1mg%'  and dangbaoche like '%thuốcnhỏmắt%'  then '1MG/1ML' 
                    when chua_hoatchat = 1.09 and ndhl like '%15ml%'and dangbaoche like '%thuốcnhỏmắt%'  then '45MG/15ML' 
                    when chua_hoatchat = 1.1 and ndhl like '%1ml%' and ndhl like '%2mg%' and dangbaoche like '%thuốcnhỏmắt%'  then '2MG/1ML'   
                    when chua_hoatchat = 1.11 and ndhl like '%64mcg%' and dangbaoche like '%thuốcxịtmũi%'  then '64MCG'     
                    when chua_hoatchat = 1.12 and ndhl like '%50mcg%' and dangbaoche like '%thuốcxịtmũi%'  then '50MCG'    
                    when chua_hoatchat = 1.13 and ndhl like '%0,05\\%%'and dangbaoche like '%thuốcdùngngoài%'  then '0,05%'     
                    when chua_hoatchat = 1.14 and ndhl like '%12ml%' and ndhl like '%21,6mg%' and dangbaoche like '%thuốcnhỏmắt%'  then '21,6MG/12ML'   
                    when chua_hoatchat = 1.15 and (ndhl like '%200,000iu%' or ndhl like '%200000iu%')  and dangbaoche like '%thuốcnhỏtai%'  then '200.000IU'  
                    when chua_hoatchat = 1.16 and ndhl like '%2\\%%'  and ndhl not like '%,2\\%%'  and dangbaoche like '%thuốctácdụngtạiniêmmạcmiệng%'  then '2%'   
                    when chua_hoatchat = 1.17 and ndhl like '%50mcg%' and quycachdonggoi like '%60liều%' and dangbaoche like '%thuốcxịtmũi%'  then '50mcg/1 liều xịt/60 liều'    
                    when chua_hoatchat = 1.17 and ndhl like '%50mcg%'  and quycachdonggoi like '%120liều%'and dangbaoche like '%thuốcxịtmũi%'  then '50mcg/1 liều xịt/120 liều'    
                    when chua_hoatchat = 2 and ndhl like '%0,137mg%' and ndhl like '%0,05mg%' and dangbaoche like '%thuốcxịtmũi%'  then '0,137MG + 0,05MG'               
                    when chua_hoatchat = 2.1 and ndhl like '%15mg%' and ndhl like '%5mg%' and ( LENGTH(ndhl) - LENGTH(Replace(ndhl, '5mg', '')) )=6 and ndhl like '%5ml%' 
                                and dangbaoche like '%thuốcnhỏmắt%'  then '15MG/5ML + 5MG/5ML' 
                    when chua_hoatchat = 2.2 and ndhl like '%100mg%' and ndhl like '%50mg%'  and dangbaoche like '%thuốcdùngngoài%'  then '100MG + 50 MG' 
                    when chua_hoatchat = 2.3 and ndhl like '%390mg%'  and ndhl like '%336,6mg%' 
                              and dangbaoche like '%dungdịch%' and  dangbaoche like '%hỗndịch%'and  dangbaoche like '%nhũdịchuống%' then '390MG + 336,6MG' 

                    when chua_hoatchat = 3 and ndhl like '%178,5mg%' and ndhl like '%0,175mg%'  and ndhl like '%1mg%'  and dangbaoche like '%viên%' then upper('178,5mg + 0,175mg + 16mg')

                    when chua_hoatchat = 3.1 and ndhl like '%500mg%' and ndhl like '%160mg%'  and ndhl like '%267mg%'
                               and dangbaoche like '%dungdịch%' and  dangbaoche like '%hỗndịch%'and  dangbaoche like '%nhũdịchuống%' then upper('500mg + 160mg + 267mg')

                    when chua_hoatchat = 3.2 and ndhl like '%400mg%' and ndhl like '%351,9mg%'  and ndhl like '%50mg%'  
                               and dangbaoche like '%dungdịch%' and  dangbaoche like '%hỗndịch%'and  dangbaoche like '%nhũdịchuống%' then  upper('400mg + 351,9mg + 50mg')

                    when chua_hoatchat = 3.3 and ( ndhl like '%35,000iu%' or ndhl like '%35000iu%') and ( ndhl like '%60,000iu%' or ndhl like '%60000iu%')  and ndhl like '%10mg%'

                               and dangbaoche like '%thuốcnhỏmắt%' then  upper('35.000iu + 60.000iu + 10mg')

                    when chua_hoatchat = 3.4 and ndhl like '%35mg%' and ( ndhl like '%10,000iu%' or ndhl like '%10000iu%')  and ndhl like '%10mg%'  
                               and dangbaoche like '%thuốcnhỏtai%'  then  upper('35mg + 10.000iu + 10mg')
    
else null end as ndhl_clean

 from  data_hoatchat_result1  
),

result1 as (
select *except(tenthuoc,tencososanxuat,nhathautrungthau,nuocsanxuat ),

Case when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-18971-13' then 'vd-26895-17'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-15719-12' then 'vn-17834-14'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-22225-19' then 'vn-22226-19'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-32566-19' then 'vd-32567-19'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-18381-13' then 'vd-35219-21'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-28068-17' then 'vd-28069-17'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') in ('vd-28338-17','vd-28340-17','vd-28339-17') then 'vd-28341-17'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-28068-17' then 'vd-28069-17'
when replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-26427-17' then 'vd-26433-17'
else replace(replace(left(sdkgpnk,11),'(',''),'c','')
end  as sdk1,

Case when nuocsanxuat in('BỈ','BELGIUM','S.A.ALCON-COUVREURN.V') then 'BỈ' 
     when nuocsanxuat in('VN','VIỆTNAM','VIETNAM') or nuocsanxuat like 'VIỆT%' or nuocsanxuat like '%CÔNGTY%' or nuocsanxuat like '%NAM' 
     or nuocsanxuat like '%VIDIPHA%' or nuocsanxuat like '%VIỆN%' or nuocsanxuat like '%VIÊN%'
     then 'VIỆT NAM'
     when nuocsanxuat like 'ANH%' or  nuocsanxuat in('NORTONHEALTHCARELIMITEDT/AIVAXPHARMACEUTICALSUK','UNITEDKINGDOM','UK') then 'ANH'
     when nuocsanxuat like '%AUSTRIA%' then 'ÁO'
     when nuocsanxuat in('CHSÍP','CYPRUS','SÍP') or nuocsanxuat like '%CYPRUS%' then 'CỘNG HÒA SÍP'
     when nuocsanxuat in('CSSXVÀĐÓNGGÓI:PHÁP;CHỨNGNHẬNXUẤTXƯỞNG:BỈ','PHÁP,CSSXVÀĐÓNGGÓI:PHÁP;CHỨNGNHẬNXUẤTXƯỞNG:BỈ','PHÁP','PHÁP') then 'PHÁP'
     when nuocsanxuat like '%KOREA%' or nuocsanxuat like 'HÀNQUỐC' then 'HÀN QUỐC'
     when nuocsanxuat in('KRKA,D.D.,NOVOMESTO','SLOVENIA') then 'SLOVENIA'
     when nuocsanxuat ='FRANCE' then 'PHÁP'
     when nuocsanxuat like '%GREECE%' or nuocsanxuat like 'HYLẠP' or nuocsanxuat like '%VIANEX%' 
     or nuocsanxuat like '%PARENTERALSOLUTIONSINDUSTRY%'  then 'HY LẠP'
     when nuocsanxuat ='GERMANY' or nuocsanxuat like '%ĐỨC%' then 'ĐỨC'
     when nuocsanxuat in('MIPHARMS.P.A','ITALY','ITALIA','YTALY') or nuocsanxuat like '%CSSX:Ý%'
           or nuocsanxuat like 'Ý%' or nuocsanxuat='Ý' then 'Ý'
     when nuocsanxuat like '%MOLDOVA%' then 'CỘNG HÒA MOLDOVA'
     when nuocsanxuat like '%NHẬT%' or nuocsanxuat ='JAPAN' then 'NHẬT BẢN'
     when nuocsanxuat in( 'SWEDEN','THỤYĐIỂN','ASTRAZENECAAB') or  nuocsanxuat like '%ĐIỂN' then 'THỤY ĐIỂN'
     when nuocsanxuat in( 'SPAIN','TÂYBANNHA','TÂYBANHA') or nuocsanxuat like '%TÂYBANNHA%'then 'TÂY BAN NHA'
     when nuocsanxuat in( 'THỔNHĨKỲ','THỔNHĨKỲ','THỔNHIKỲ','TURKEY') or nuocsanxuat like '%TURKEY%' then 'THỔ NHĨ KỲ'
     when nuocsanxuat in( 'THÁILAN','THAILAND') then 'THÁI LAN'
     when nuocsanxuat in( 'UNITEDSTATES','USA') or nuocsanxuat like '%CSSX:MỸ%' then 'MỸ'
     when nuocsanxuat in( 'AUROBINDOPHARMALTD','INDIA','ẤNĐỘ') or nuocsanxuat like '%ẤNĐỘ%' or nuocsanxuat like '%ZIMLABORATORI%' 
     or nuocsanxuat like '%WOCKHARDT%'
      then 'ẤN ĐỘ'
     when nuocsanxuat in( 'ĐÀILOAN') or nuocsanxuat like '%LOAN'or nuocsanxuat like '%TAIWAN%' then 'ĐÀI LOAN'
     when nuocsanxuat like '%IRELAND%' then 'CỘNG HÒA IRELAND'
     when nuocsanxuat like '%MẠCH' then 'ĐAN MẠCH'
     when trim(nuocsanxuat) like '%QUỐC' or nuocsanxuat like '%YICHANGHUMANWELL%' then 'TRUNG QUỐC'
     when nuocsanxuat like '%MALAYSIA%' or nuocsanxuat like '%XLLABORATORIES%' then 'MALAYSIA'
     when nuocsanxuat like '%UKARAI%' or nuocsanxuat like '%UKRAI%' then 'UKRAINE'
     when nuocsanxuat like '%WORKSPOLFAS%' then 'BA LAN'
    --  when nuocsanxuat like 
      else trim(upper(nuocsanxuat_ori)) end as nuocsanxuat,

Case 

     when tenthuoc ='AUROPODOX' then  'AUROPODOX200'
     when tenthuoc ='ALZOLE' then 'ALZOLE40'
     when tenthuoc like '%AVAMYS%' and ndhl like '%30%' then 'AVAMYS NASAL SPRAYSUSP27.5MCG30DOSE'
     when tenthuoc like '%AVAMYS%' and (ndhl like '%60%' or tenthuoc like '%60%') then "AVAMYS SPRAYSUS.27.5MCG60'S"
     when tenthuoc like '%AVAMYS%' and (ndhl like '%120%' or tenthuoc like '%120%') then "AVAMYS NASAL SPRAYSUS27.5MCG120ʹS"
     when tenthuoc like '%AVAMYS%' and (ndhl not like '%120%' or tenthuoc like '%60%'or tenthuoc like '%30%' ) then "AVAMYS NASAL SPRAYSUS27.5MCG120ʹS"
     when tenthuoc like '%BACTIRID%' then 'BACTIRID'
     when tenthuoc like '%BICELOR500%' then 'BICELOR500DT'
     when tenthuoc like '%BICELOR250DT%' then 'BICELOR250DT'
     when tenthuoc like '%BUDESONIDE%' and replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-15282-12' then 'BUDESONIDE TEVA'
     when (tenthuoc like'CEFIXIM%' and ndhl like '%100mg%') or tenthuoc like '%CEFIXIM100%' then 'CEFIXIM100'
     when (tenthuoc like 'CEFIXIME%' and ndhl like '%50mg%') or tenthuoc like'%CEFIXIM50%' then 'CEFIXIM50'
     when tenthuoc ='CEFIXIM200' or (tenthuoc like '%CEFIXIME%'and ndhl like '%200mg%') then 'CEFIXIM200'
     when tenthuoc like '	CEFODOMID100%' then '	CEFODOMID100'
     when tenthuoc like 'CEFPODOXIM40%' then 'CEFPODOXIM40'
     when tenthuoc like 'CEFODOMID100%' then 'CEFODOMID100'
     when tenthuoc like '%CEFPODOXIM%' and ndhl like '%200%' then 'CEFPODOXIM200'
     when (tenthuoc like 'CEFACLOR%' or tenthuoc like 'CECLOR%'or chua_hoatchat = 1.06) and ndhl like '%125%' then 'CEFACLOR125'
     when (tenthuoc like 'CEFACLOR%' or tenthuoc like 'CECLOR%'or chua_hoatchat = 1.06) and ndhl like '%250%' then 'CEFACLOR250'
      when (tenthuoc like 'CEFACLOR%'or tenthuoc like 'CECLOR%'or chua_hoatchat = 1.06)  and ndhl like '%500%' then 'CEFACLOR500'
      when chua_hoatchat = 1.06  and ndhl like '%375%' then 'CEFACLOR375' 
      when tenthuoc like '%CEFUROXIM%' and ( ndhl like '%125%' or tenthuoc like '%125%') then 'CEFUROXIM125'
      when tenthuoc like '%CEFUROXIM%' and  (ndhl like '%250%'  or tenthuoc like '%250%')then 'CEFUROXIM250'
      when tenthuoc like '%CEFUROXIM%' and  (ndhl like '%500%'  or tenthuoc like '%500%') then 'CEFUROXIM500'
      when tenthuoc like '%CEFUROXIM%' and  (ndhl like '%750%' or tenthuoc like '%750%') then 'CEFUROXIM750'
      when tenthuoc like '%CEFUROXIME1G%'  then 'CEFUROXIM1000'
      when tenthuoc like '%CEPOXITIL%' and ndhl like '%200%' then 'CEPOXITIL200'
      when tenthuoc like '%CEPOXITIL%' and ndhl like '%100%' then 'CEPOXITIL100'
      when tenthuoc like 'DERMOVATE%' then 'DERMOVATE'
      when tenthuoc like 'DISOVERIM%' and ndhl like '%100%' then 'DISOVERIM100'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-18307-14' then 'EUMOVATE CREAM'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-21337-18' then 'EYRUS OPHTHALMIC SUSPENSION'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-28075-17' then 'FABAFIXIM200DT'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-16267-13' then 'FLIXOTIDE EVOHALER'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-17473-13' then 'FUCIDIN H CREAM15G'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-18309-14' then 'FLIXOTIDE NEBULES0.5MG/2ML'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-18451-14' then 'FLUMETHOLON0,02'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-20281-17' then 'FLIXONASE'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='qlvx-1079-1' then 'SYNFLORIX'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-15402-11' then 'GASTRO-KITE'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-18273-13' then 'VILANTA'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-22345-15' then 'STADNEX20CAP'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-27892-17' then 'IMEDOXIME200'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-30588-18' then 'CLOBETASOL0.05%'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-32408-19' then 'GELACTIVE FORTE'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-34198-20' then 'LOCGODA0,1%'
      when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vd-35219-21' then 'ALZOLE40'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-14739-12' then 'MIKO-PENOTRAN'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-15282-12' then 'BUDESONIDE TEVA'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-20513-17' then 'ZINNAT SUSPENSION'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-15419-12' then 'VISMED'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') in('vn-15719-12','vn-17834-14' ) then 'NEXIUM'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-17744-14' then 'CEFACLOR500'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-1807-14' then 'V-PROX200'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-19343-15' then 'SANLEIN0.3'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-19559-16' then 'PULMICORT RESPULES'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-19782-16' then 'NEXIUM MUPS40'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-19783-16' then 'NEXIUM MUPS20'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-19963-16' then 'ZINNAT TABLETS250'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-20514-17' then 'ZINNAT TABLETS500'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-20624-17' then 'XORIMAX500'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-21322-18' then 'SUDOMON50MCG/1DOS'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-20624-17' then 'XORIMAX500'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-21629-18' then 'TOBRADEX'
       when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-21666-19' then 'PULMICORT RESPULES'
        when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-22225-19' and chua_hoatchat =1.15  then 'OTOFA'
        when  replace(replace(left(sdkgpnk,11),'(',''),'c','') in('vn-22225-19','vn-22226-19') and chua_hoatchat =3.3  then 'POLYDEXA'
        when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-22239-19' then 'MEDOOME40'
        when  replace(replace(left(sdkgpnk,11),'(',''),'c','') ='vn-9663-10' then 'ZINNAT SUSPENSION'
       else trim(upper(tenthuoc_ori)) end as tenthuoc,
  Case 
       when tencososanxuat like '%MERAP%' then 'CÔNG TY CỔ PHẦN TẬP ĐOÀN MERAP'
       when tencososanxuat like '%VINPHACO%' OR tencososanxuat like '%DPVĨNHPHÚC%'  OR tencososanxuat like '%DƯỢCPHẨMVĨNHPHÚC%' then 'CÔNG TY CỔ PHẦN DƯỢC PHẨM VĨNH PHÚC'
       when tencososanxuat like '%DƯỢCPHẨMKHÁNHHÒA%' OR tencososanxuat like '%DPKHÁNHHÒA%' OR tencososanxuat like '%KHÁNHHOÀ%' OR tencososanxuat like '%KHÁNHHÒA%' then 'CÔNG TY CỔ PHẦN DƯỢC PHẨM KHÁNH HÒA'
       when tencososanxuat like '%TRUNGƯƠNG2%' or tencososanxuat like '%TRUNGƯƠNGII%' OR tencososanxuat like '%TW2%' then upper('Công ty cổ phần dược phẩm trung ương 2 DOPHARMA')
       when tencososanxuat like '%TRUNGƯƠNG1%' or tencososanxuat like '%TRUNGƯƠNGI%' OR tencososanxuat like '%TW1%' or tencososanxuat like '%PHARBACO%' then upper('Công ty cổ phần Dược phẩm Trung ương 1 Pharbaco')
       when tencososanxuat like '%VIDIPHA%' then upper('Công Ty Cổ phần Dược Phẩm Trung Ương Vidipha')
       when tencososanxuat like '%ACSDOBFARS%' then upper('ACS Dobfar S.p.A')
       when tencososanxuat like '%ASTRAZENECAAB%' then upper('ASTRAZENECAAB')
       when tencososanxuat like '%AUROBINDOPHARMA%' then upper('AUROBINDO PHARMA LTD')
       when tencososanxuat like '%BALKANPHARMA%' then upper('BALKAN PHARMA-RAZGRAD AD')
       when tencososanxuat like '%ALCONRESEARCH%' then upper('ALCON RESEARCH-LLC')
       when tencososanxuat like '%ALLERGANPHARMA%' then upper('Allergan Pharmaceuticals Ireland')
       when tencososanxuat like '%ANFARMHELL%' then upper('ANFARM HELLASS.A')
      --  when tencososanxuat like '%BIDIPHAR%' then upper('BIDIPHAR-VIỆTNAM')
       when tencososanxuat like '%CADILAHEALTH%' then upper('CADILA HEALTHCARE LIMITED')
       when tencososanxuat like '%CENTERFORGENE%' then upper('center for genetic engineering and biotechnology')
       when tencososanxuat like '%AGIMEXPHARM%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM AGIMEXPHARM')
       when tencososanxuat like '%IMEXPHARM%' and tencososanxuat not like '%AGIMEXPHARM%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM IMEXPHARM')
       when tencososanxuat like '%CIPLALTD%' then upper('CIPLA LTD')
       when tencososanxuat like '%CPC1%' or tencososanxuat like '%CPCI%' then upper('Công ty Cổ phần Dược Phẩm Trung Ương CPC1')
       when tencososanxuat like '%CISBIO%' then upper('CIS bio international')
       when tencososanxuat like '%:GLAXOSMITHKLINE%' then upper('glaxosmithkline biologicals')
        when tencososanxuat like '%:SANOFIPASTEUR%' then upper('SANOFI PASTEUR')
        when tencososanxuat like '%VIANEXS%' then upper('VIANEXS.A.-PLANTA')
      when tencososanxuat like '%CROMA%' then upper('CROMA-PHARMA-GMBH')
      when tencososanxuat like '%APIMED%' then upper('CÔNG TY CỔ PHẦN DƯỢC APIMED')
      when tencososanxuat like '%ANTHIÊN%' then upper('CÔNG TY CỔ PHẦN DƯỢC AN THIÊN')
      when tencososanxuat like '%DƯỢCKHOA%' then upper('CÔNG TY CỔ PHẦN DƯỢC KHOA')
      when tencososanxuat like '%DƯỢCPHẨMHÀNỘI%' or tencososanxuat like '%DPHÀNỘI%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM HÀ NỘI')
      when tencososanxuat like '%HÀTÂY%' or tencososanxuat like '%HÀTÂY%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM HÀ TÂY')
      when tencososanxuat like '%MEDISUN%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM MEDISUN')
      when tencososanxuat like '%MINHDÂN%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM MINH DÂN')
      when tencososanxuat like '%TV.PHARM%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM TV.PHARM')
      when tencososanxuat like '%DƯỢCPHẨMVCP%'or tencososanxuat like '%DPVCP%' or tencososanxuat like '%DƯỢCPHẨMVCP%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM VCP')
     when tencososanxuat like '%SINHHỌCYTẾ%' then upper('Công ty CỔ PHẦN Dược Phẩm & Sinh Học Y Tế')
     when tencososanxuat like '%DOMESCO%' then upper('Công ty CỔ PHẦN Xuất nhập khẩu Y Tế Domesco')
     when tencososanxuat like '%ĐẠTVIPHÚ%' then upper('Công ty Cổ Phần Dược Phẩm Đạt Vi Phú')
     when tencososanxuat like '%ĐỒNGNAI%' then upper('Công ty Cổ Phần Dược ĐỒNG NAI')
     when tencososanxuat like '%MEKOPHAR%' then upper('Công ty Cổ phần Hoá - Dược phẩm Mekophar')
     when tencososanxuat like '%HÓADƯỢC%'or tencososanxuat like '%HOÁDƯỢC%' then upper('CÔNG TY CỔ PHẦN HÓA DƯỢC VIỆT NAM')
     when tencososanxuat like '%PYMEPHARCO%' then upper('CÔNG TY CỔ PHẦN PYMEPHARCO')
     when tencososanxuat like '%MEDIPHARCO%' then upper('CÔNG TY CỔ PHẦN DƯỢC MEDIPHARCO')
     when tencososanxuat like '%MEBIPHAR%-AUSTRAPHARM%' then upper('CÔNG TY LIÊN DOANH DƯỢC PHẨM MEBIPHAR - AUSTRAPHARM')
     when tencososanxuat like '%SHINPOONG%' then upper('CÔNG TY TNHH DƯỢC PHẨM SHINPOONG DAEWOO')
     when tencososanxuat like '%TRUSTFARMA%' then upper('CÔNG TY CỔ PHẦN TRUST FARMA QUỐC TẾ')
     when tencososanxuat like '%BRVHEALTH%' then upper('Công ty TNHH BRV HEALTHCARE')
     when tencososanxuat like '%CỬULONG%' or tencososanxuat like '%CỦULONG%' then upper('Công ty Cổ phần Dược phẩm Cửu Long')
     when tencososanxuat like '%PHARMAUSA%' then upper('Công ty Cổ phần US pharma usa')
     when tencososanxuat like '%SAVI%' then upper('Công ty cổ phần Dược phẩm SaVi')
     when tencososanxuat like '%BOSTONVIỆTNAM%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM BOSTON VIỆT NAM')
     when tencososanxuat like '%BIDIPHAR%' or tencososanxuat like '%YTẾBÌNHĐỊNH%' then upper('CÔNG TY CP DƯỢC - TRANG THIẾT BỊ Y TẾ BÌNH ĐỊNH')
     when tencososanxuat like '%PHARMEDIC%'  then upper('Công Ty Cổ Phần Dược Phẩm Dược Liệu Pharmedic')
     when tencososanxuat like '%PHƯƠNGĐÔNG%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM PHƯƠNG ĐÔNG')
     when tencososanxuat like '%TENAMYD%'  then upper('Công Ty Cổ Phần Dược Phẩm Tenamyd')
     when tencososanxuat like '%CỔPHẦN239%'  or tencososanxuat like '%23THÁNG9%'  then upper('CÔNG TY CỔ PHẦN 23 THÁNG 9')
     when tencososanxuat like '%BVPHARMA%'   then upper('Công ty Cổ Phần BV Pharma')
     when tencososanxuat like '%DƯỢCPHẨM3/2%'   then upper('Công Ty Cổ Phần Dược Phẩm 3/2')
     when tencososanxuat like '%HÀTĨNH%'   then upper('Công ty cổ phần Dược Hà Tĩnh')
     when tencososanxuat like '%STELLAPHARM%'   then upper('Công ty TNHH LD STELLAPHARM - Chi nhánh 1')
     when tencososanxuat like '%QUẢNGBÌNH%'   then upper('Công Ty Cổ Phần Dược Phẩm QUẢNG BÌNH')
     when tencososanxuat like '%DERMAPHARM%'   then upper('Công ty TNHH liên doanh HASAN- DEMAPHARM')
     when tencososanxuat like '%DAEWOONG%'   then upper('Daewoong Pharmaceuticals')
     when tencososanxuat like '%BẾNTRE%'   then upper('Công Ty Cổ Phần Dược Phẩm BẾN TRE')
     when tencososanxuat like '%VACOPHARM%'   then upper('Công Ty Cổ Phần Dược VACOPHARM')
     when tencososanxuat like '%TIPHARCO%'   then upper('Công Ty Cổ Phần Dược Phẩm TIPHARCO')
    --  when tencososanxuat like '%GLAXOSMITHKLINE%'   then upper('GlaxoSmithKline Biologicals SA')
     when tencososanxuat like '%GLAXO%'   then upper('Glaxo Operations UK Ltd')
     when tencososanxuat like '%MEYER%'   then upper('Công ty Liên doanh Meyer-BPC')
     when tencososanxuat like '%BRVHEATHCARE%'   then upper('CÔNG TY TNHH BRV HEALTHCARE')
     when tencososanxuat like '%TRAPHACOHƯNGYÊN%'   then upper('Công ty TNHH Traphaco Hưng Yên')
     when tencososanxuat like '%GLENMARK%'   then upper('GLENMARK PHARMACEUTICALS LTD')
     when tencososanxuat like '%HANLIM%'   then upper('HANLIM PHARM.CO.LTD')
    --  when tencososanxuat like '%MEDOCHEMIELTD%'   then upper('MEDOCHEMIE LTD.-FACTORYC')
     when tencososanxuat like '%INDUSTRIAQUIMICAY%'   then upper('INDUSTRIA QUIMICA Y FARMACEUTICA VIR SA')
     when tencososanxuat like '%HOLOPACK%'   then upper('HOLOPACK Verpackungstechnik GmbH')
     when tencososanxuat like '%KOREAPHARMACO%'   then upper('KOREA PHARMACO LTD')
     when tencososanxuat like '%LABORAT%'   then upper('Laboratorios Normon SA')
     when tencososanxuat like '%KRKA%'   then upper('KRKA, D.D., Novo Mesto')
     when tencososanxuat like '%LEKPHARM%'   then upper('Lek Pharmaceuticals')
     when tencososanxuat like '%MEDLACPHARMAITALY%'   then upper('Công ty TNHH sản xuất dược phẩm Medlac pharma Italy')
     when tencososanxuat like '%UNITEDINTERNATIONALPHARMA%'   then upper('Công ty TNHH United International Pharma')
     when tencososanxuat like '%MEDICRAFT%'   then upper('MEDICRAFT PHARMACEUTICALS PRIVATE LIMITED')
     when tencososanxuat like '%MEDOCHEMIE%'   then upper('MEDOCHEMIE LTD-FACTORYC')
     when tencososanxuat like '%NORTONHEALTH%'   then upper('NORTON HEALTHCARE LIMITED')
     when tencososanxuat like '%OLIC%'   then upper('OLIC(THAILAND)LTD')
     when tencososanxuat like '%REMEDINAS%'   then upper('REMEDINAS A')
     when tencososanxuat like '%RPGLIFESCIENCES%'   then upper('RPG LIFE SCIENCES LTD')
     when tencososanxuat like '%COUVREURN%'   then upper('S A ALCON-COUVREURN V')
     when tencososanxuat like '%SAMCHUN%'   then upper('Sam Chun Dang Pharm Co Ltd')
     when tencososanxuat like '%SANTAFARMA%'  or tencososanxuat like '%SANTENPHARM%'  then upper('Santa Farma Pharmaceuticals')
     when tencososanxuat like '%SLAVIAPHARMS%'   then upper('S C SLAVIAPHARMS R L')
     when tencososanxuat like '%SAMILPHARM%'   then upper('SAMILPHARM CO LTD')
     when tencososanxuat like '%SCHERING%'   then upper('SCHERING-PLOUGHLABON V')
     when tencososanxuat like '%SUNPHARMA%'   then upper('Sun Pharmaceutical Industries Ltd')
     when tencososanxuat like '%SQUAREPHARMA%'   then upper('SQUARE PHARMACEUTICALS LTD')
     when tencososanxuat like '%YASHMEDI%'   then upper('YASH MEDICARE PVT,LTD')
     when tencososanxuat like '%VALPHARMA%'   then upper('VAL PHARMA INTERNATIONALS P A')
     when tencososanxuat like '%PHÓNGXẠ%'   then upper('trung tâm nghiên cứu và điều chế đồng vị phóng xạ')
  else upper(replace(tencososanxuat,'.',' ')) end as tencososanxuat,
-- *, 

 Case when nhathautrungthau like '%phanam%' then upper('Công Ty Cổ Phần Dược Pha Nam')
     when  (nhathautrungthau like '%trungương2%'or nhathautrungthau like '%dượcliệutw2%' or nhathautrungthau like '%tw2%') and nhathautrungthau like '%tnhh%'  then upper('CÔNG TY TNHH MỘT THÀNH VIÊN DƯỢC LIỆU TW2') 
      when  (nhathautrungthau like '%dượcliệutrưngương2%' or nhathautrungthau like '%dượcliệutw2%' or nhathautrungthau like '%dượcliệutrungương2%' or nhathautrungthau like '%tw2%'
      or nhathautrungthau like '%trunguong2%'
      )and ( nhathautrungthau  like '%cp%' or nhathautrungthau  like '%cổphần%') then upper('công ty cổ phần dược liệu trung ương 2') 
       when   nhathautrungthau like '%tw2%'then upper('công ty cổ phần dược liệu trung ương 2')      
      when  nhathautrungthau like '%sapharco%' then upper('Công ty TNHH MTV Dược Sài Gòn (Sapharco)')
      when  nhathautrungthau like '%hoàngđức%' then upper('Công ty TNHH Dược Phẩm & Trang Thiết Bị Y Tế Hoàng Đức')
      when  nhathautrungthau like '%đôngnampharma%' then upper('CÔNG TY TNHH ĐÔNG NAM PHARMA')
      when  nhathautrungthau like '%minhdân%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM MINH DÂN')
      when  nhathautrungthau like '%hiềnmai%' then upper('Công Ty Tnhh Dược Phẩm Hiền Mai')
      when  nhathautrungthau like '%shinpoongdaewoo%' or nhathautrungthau like '%shinpoong%'  or upper(nhathautrungthau) like '%SINPOOG%' then upper('Công Ty TNHH Dược Phẩm Shinpoong Daewoo')
      when  nhathautrungthau like '%vimedimexbìnhdương%' or nhathautrungthau like '%vinmedimex%' then upper('Công Ty Tnhh Một Thành Viên Vimedimex Bình Dương')
      when  nhathautrungthau like '%huycường%' then upper('CÔNG TY TNHH DƯỢC PHẨM HUY CƯỜNG')
      when  nhathautrungthau like '%cpc1%' and  nhathautrungthau not like '%cn%' then upper('Công ty Cổ phần Dược Phẩm Trung Ương CPC1 - Hà Nội') 
      when  (nhathautrungthau like '%cpc1hànội%' or nhathautrungthau like '%cpc1hànội%') and nhathautrungthau not like '%cnhcm%' then upper('Công ty Cổ phần Dược Phẩm Trung Ương CPC1 - Hà Nội')
      when  nhathautrungthau like '%cpc1%' and  nhathautrungthau  like '%cn%' then upper('Công ty Cổ phần Dược Phẩm Trung Ương CPC1 - CN TPHCM')
      when  nhathautrungthau like '%afpgiavũ%'  then upper('CÔNG TY CỔ PHẦN AFP GIA VŨ')
      when  nhathautrungthau like '%anthiên%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM AN THIÊN')
      when  nhathautrungthau like '%at&c%' then upper('CÔNG TY TNHH DƯỢC PHẨM AT&C')
      when  nhathautrungthau like '%avispharm%' and nhathautrungthau like '%bmt%' then upper('CÔNG TY CỔ PHẦN DƯỢC AVISPHARM BMT')
      when  nhathautrungthau like '%bamephar%' then upper('Công ty Cổ phần Dược - Vật tư Y Tế Đăk Lăk - BAMEPHARM')
      when  nhathautrungthau like '%benephar%' then upper('Công ty TNHH Dược Phẩm Benephar')
      when  nhathautrungthau like '%bidiphar%' or nhathautrungthau like '%bìnhđịnh%' or nhathautrungthau like '%ytếbìnhđịnh%' then upper('Công ty Cổ phần Dược - Trang thiết bị Y tế Bình Định (BIDIPHAR)')
      when  nhathautrungthau like '%bìnhviệtđức%' then upper('Công ty Dược Phẩm Bình Việt Đức')
      when  nhathautrungthau like '%bếntre%' then upper('Công ty Cổ phần Dược phẩm Bến Tre - Bepharco')
      when  nhathautrungthau like '%cadila%' then upper('Cadila Pharmaceuticals')
      when  nhathautrungthau like '%tv.pharmtạitiềngiang%' then upper('CHI NHÁNH CÔNG TY CỔ PHẦN DƯỢC PHẨM TV.PHARM TẠI TIỀN GIANG')
      when  nhathautrungthau like '%codupha%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM TRUNG ƯƠNG CODUPHA')
      when  nhathautrungthau like '%mâyvàng%' then upper('CÔNG TY TNHH MTV THƯƠNG MẠI DỊCH VỤ DU LỊCH MÂY VÀNG')
      when  nhathautrungthau like '%cpdn%' then upper('Canadian Pharmaceutical Distribution Network')
      when  nhathautrungthau like '%ctpharma%' then upper('ct pharma')
      when  nhathautrungthau like '%ythànội%' or nhathautrungthau like '%ytếhànội%' or nhathautrungthau like '%hapharco%' then upper('Công ty Cổ phần Dược phẩm Thiết bị Y tế Hà Nội')
      when  nhathautrungthau like '%thuậnanphát%' then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM THUẬN AN PHÁT')
      when  nhathautrungthau like '%tv.pharm%' or nhathautrungthau like '%tv' or nhathautrungthau like '%tvpharm%' then upper('Công Ty Cổ Phần Dược Phẩm TV.PHARM')
      when  nhathautrungthau like '%vĩnhphúc%'  then upper('Công ty Cổ phần Dược phẩm Vĩnh Phúc')
      when  nhathautrungthau like '%khánhhòa%'  or nhathautrungthau like '%khánhhoà%' then upper('Công ty Cổ phần Dược phẩm khánh hòa')
       when  nhathautrungthau like '%t.n.t%'  then upper('CÔNG TY CỔ PHẦN DƯỢC VÀ THIẾT BỊ Y TẾ T.N.T')
       when  nhathautrungthau like '%ytếđànẵng%' or nhathautrungthau like '%ytđànẵng%'  then upper('Công ty Cổ phần Dược - Thiết bị Y tế Đà Nẵng')
       when  nhathautrungthau like '%fulink%'  then upper('CÔNG TY CỔ PHẦN FULINK VIỆT NAM')
       when  nhathautrungthau like '%gonsa%'  then upper('CÔNG TY CỔ PHẦN GONSA')
       when  nhathautrungthau like '%phúclong%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM PHÚC LONG')
       when  nhathautrungthau like '%vacopharm%'  then upper('Công ty Cổ phần Dược Vacopharm')
       when  nhathautrungthau like '%imexpharm%'  then upper('Công Ty Cổ Phần Dược Phẩm Imexpharm')
       when  nhathautrungthau like '%vidipha%'  then upper('Công ty Cổ phần Dược phẩm Trung ương Vidipha')
       when  nhathautrungthau like '%thuậnphát%'  then upper('Công ty Cổ Phần Thương Mại Dược Phẩm Và Trang Thiết Bị Y Tế Thuận Phát')
       when  nhathautrungthau like '%kimpharma%'  then upper('CÔNG TY TNHH KIM PHARMA')
       when  nhathautrungthau like '%dượcsàigòn%'  then upper('CÔNG TY TNHH MỘT THÀNH VIÊN DƯỢC SÀI GÒN')
       when  nhathautrungthau like '%u.n.i%' or nhathautrungthau like '%u.n,i%' or nhathautrungthau like '%u,n,i%' or nhathautrungthau like '%u,n.i%' then upper('CÔNG TY TNHH DƯỢC PHẨM U.N.I VIỆT NAM')
       when  nhathautrungthau like '%tbytaca%'  then upper('CÔNG TY TNHH DƯỢC PHẨM VÀ THIẾT BỊ Y TẾ ACA')
       when  nhathautrungthau like '%hồnglộcphát%'  then upper('Công ty TNHH Dược Hồng Lộc Phát')
       when  nhathautrungthau like '%tamsơn%'  then upper('CÔNG TY CỔ PHẦN ĐẦU TƯ TẬP ĐOÀN TAM SƠN')
       when  nhathautrungthau like '%hànamninh%'  then upper('CÔNG TY CP DƯỢC PHẨM HÀ NAM NINH')
       when  nhathautrungthau like '%minhtâm%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM MINH TÂM')
       when  nhathautrungthau like '%đấtviệt%'  then upper('Công ty Cổ phần Dược phẩm Đất Việt')
       when  nhathautrungthau like '%báchlinh%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM VÀ THIẾT BỊ Y TẾ BÁCH LINH')
       when  nhathautrungthau like '%vănlam%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM VĂN LAM')
       when  nhathautrungthau like '%a.ppharma%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM AP PHARMA')
       when  nhathautrungthau like '%ythảidương%'  then upper('CÔNG TY CỔ PHẦN DƯỢC VẬT TƯ Y TẾ HẢI DƯƠNG')
       when  nhathautrungthau like '%hàphương%'  then upper('CÔNG TY CỔ PHẦN DƯỢC HÀ PHƯƠNG')
       when  nhathautrungthau like '%medipharco%'  then upper('Công Ty Cổ Phần Dược Medipharco')
        when  nhathautrungthau like '%annguyên%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM AN NGUYÊN')
        when  nhathautrungthau like '%hưngphúc%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM HƯNG PHÚC')
        when  nhathautrungthau like '%kimphúc%'  then upper('Công Ty Dược Phẩm Kim Phúc')
        when  nhathautrungthau like '%sôngnhuệ%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM SÔNG NHUỆ')
        when  nhathautrungthau like '%tânan%'  then upper('CÔNG TY TNHH DƯỢC PHẨM TÂN AN')
        when  nhathautrungthau like '%vcp%'  then upper('CÔNG TY TNHH DƯỢC PHẨM VCP')
        when  nhathautrungthau like '%ytếtháinguyên%'  then upper('CÔNG TY CỔ PHẦN DƯỢC VÀ VẬT TƯ Y TẾ THÁI NGUYÊN')
        when  nhathautrungthau like '%gianguyên%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM GIA NGUYỄN')
        when  nhathautrungthau like '%hoangvu%'  then upper('CÔNG TY TNHH DƯỢC PHẨM HOÀNG VŨ')
        when  nhathautrungthau like '%hồngphúcbảo%'  then upper('CÔNG TY TNHH HỒNG PHÚC BẢO')
        when  nhathautrungthau like '%khươngduy%'  then upper('CÔNG TY TNHH DƯỢC PHẨM KHƯƠNG DUY')
        when  nhathautrungthau like '%dượcphẩmtháinguyên%'  then upper('Công Ty Cổ Phần Thương Mại Dược Phẩm Thái Nguyên')
        when  nhathautrungthau like '%koniva%' or  nhathautrungthau like '%kovina%' then upper('CÔNG TY TNHH DƯỢC PHẨM KOVINA')
        when  nhathautrungthau like '%minhhiền%'  then upper('CÔNG TY TNHH THƯƠNG MẠI DƯỢC PHẨM MINH HIỀN')
        when  nhathautrungthau like '%nguyênphát%'  then upper('CÔNG TY Cổ Phần NGUYÊN PHÁT')
        when  nhathautrungthau like '%nguyễndương%'  then upper('CÔNG TY TNHH THƯƠNG MẠI DƯỢC PHẨM NGUYỄN DƯƠNG')
        when  nhathautrungthau like '%nk'  then upper('CÔNG TY TNHH KỸ THUẬT NK')
        when  nhathautrungthau like '%savi%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM SAVI')
        when  nhathautrungthau like '%áchâu%'  then upper('CÔNG TY TNHH THƯƠNG MẠI DỊCH VỤ VÀ CÔNG NGHỆ Á CHÂU')
        when  nhathautrungthau like '%hiệpthuậnthành%'  then upper('CÔNG TY TNHH DƯỢC PHẨM HIỆP THUẬN THÀNH')
        when  nhathautrungthau like '%vimedimex%'  then upper('CÔNG TY CỔ PHẦN Y DƯỢC PHẨM VIMEDIMEX')
        when  nhathautrungthau like '%pvn'  then upper('CÔNG TY CỔ PHẦN THƯƠNG MẠI DƯỢC PHẨM PVN')
        when  nhathautrungthau like '%pymepharco%'  then upper('Công ty Cổ Phần Pymepharco')
        when  nhathautrungthau like '%sagophar%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM SAGOPHAR')
        when  nhathautrungthau like '%songkhanh%'  then upper('CÔNG TY TNHH DƯỢC PHẨM SONG KHANH')
        when  nhathautrungthau like '%songviệt%'  then upper('CÔNG TY TNHH DƯỢC PHẨM SONG VIỆT')
        when  nhathautrungthau like '%thiêntâm%'  then upper('Công ty cổ phần thương mại và dược phẩm Thiên Tâm')
        when  nhathautrungthau like '%thanhphương%'  then upper('CÔNG TY TNHH THƯƠNG MẠI DƯỢC PHẨM THANH PHƯƠNG')
        when  nhathautrungthau like '%trungương3%'  then upper('CÔNG TY CỔ PHẦN DƯỢC TRUNG ƯƠNG 3')
        when  nhathautrungthau like '%việtđức%'  then upper('CÔNG TY TNHH DƯỢC PHẨM VIỆT ĐỨC')
        when  nhathautrungthau like '%vạncườngphát%'  then upper('CÔNG TY TNHH DƯỢC PHẨM VẠN CƯỜNG PHÁT')
        when  nhathautrungthau like '%đứctâm%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM ĐỨC TÂM')
        when  nhathautrungthau like '%quảngtrị%' or nhathautrungthau like '%quảngtrị%' then upper('CÔNG TY  CỔ PHẦN DƯỢC VẬT TƯ Y TẾ QUẢNG TRỊ')
        when  nhathautrungthau like '%bôngsenvàng%'  then upper('Công ty cổ phần dược liệu Bông Sen Vàng')
        when  nhathautrungthau like '%ameriver%'  then upper('CÔNG TY CỔ PHẦN AMERIVER VIỆT NAM')
        when  nhathautrungthau like '%hàtuyên%'  then upper('Công ty Dược và TBYT Hà Tuyên')
        when  nhathautrungthau like '%megamed%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM MEGAMED')
        when  nhathautrungthau like '%phúchưng%'  then upper('CÔNG TY CỔ PHẦN Y TẾ PHÚC HƯNG')
        when  nhathautrungthau like '%sohaco%'  then upper('CÔNG TY CỔ PHẦN DƯỢC PHẨM SO HA CO MIỀN NAM')
        when  nhathautrungthau like '%vadpharma%'  then upper('CÔNG TY CỔ PHẦN VAD PHARMA')
        when  nhathautrungthau like '%vihapha%'  then upper('CÔNG TY TNHH DƯỢC PHẨM VIHAPHA')
        when  nhathautrungthau like '%saođỏ%'  then upper('CÔNG TY TNHH DƯỢC PHẨM SAO ĐỎ')
        when  nhathautrungthau like '%minhquân%'  then upper('CÔNG TY TNHH THƯƠNG MẠI DƯỢC PHẨM MINH QUÂN')
        when  nhathautrungthau like 'an' or  nhathautrungthau like '%dượcphẩman%'  or  nhathautrungthau like '%dượcphâman%'or  nhathautrungthau like '%dpan%' then upper('CÔNG TY TNHH DƯỢC PHẨM AN')
        when  nhathautrungthau like '%hoànglan%'  then upper('CÔNG TY CỔ PHẦN THƯƠNG MẠI DƯỢC PHẨM HOÀNG LAN')
        when  nhathautrungthau like '%tườngthành%' or  nhathautrungthau like '%tườngthành%' then upper('CÔNG TY TNHH DƯỢC PHẨM TƯỜNG THÀNH')
        when  nhathautrungthau like '%ninhbình%' or  nhathautrungthau like '%tườngthành%' then upper('công ty tnhh dịch vụ đầu tư và phát triển y tế ninh bình')
        when  nhathautrungthau like '%h.pcát%' or  nhathautrungthau like '%tườngthành%' then upper('công ty tnhh thương mại - đầu tư - xuất nhập khẩu h.p cát')
        when  nhathautrungthau like '%tavo%' or  nhathautrungthau like '%tườngthành%' then upper('Công Ty Cổ Phần Tavo Pharma')
        when  nhathautrungthau like '%đạibắc%' or  nhathautrungthau like '%tườngthành%' then upper('công ty tnhh đại bắc miền nam')
      else upper(nhathautrungthau_ori) end as nhathautrungthau


 from result ),
  --  where upper(nhathautrungthau)  like '%CÔNG TY%' --and nhathautrungthau  like '%cpdn%'
--  ORDER BY nhathautrungthau
loc_sdk as (select * from (
  select distinct tenthuoc,tencososanxuat,sdk1, row_number() over (partition by tenthuoc,tencososanxuat order by sdk1) as loc_sdk from result1 ) where loc_sdk=1),

  nhom_thuoc as ( 
    select tenthuoc,tencososanxuat,ARRAY_TO_STRING(ARRAY_AGG(nhomthuoc),'/') as nhom 
    from (

        select distinct a.tenthuoc,a.tencososanxuat,nhomthuoc
          from result1 a 
          order by nhomthuoc
          )
    group by 1,2
  ),

  result2 as (
  -- select a.*except(sdk1),b.sdk1,
  -- Case when phanloai_thuoc is not null and nhathautrungthau like '%PHA NAM%' then 'PHA NAM' 
  --      when phanloai_thuoc is not null and ndhl_clean is not null then 'Giống' 
  --      else 'Tương tự' end as phanloai_thuoc1
  select a.*except(sdk1),b.sdk1,
  Case when phanloai_thuoc is not null and nhathautrungthau like '%PHA NAM%' and loc_hoatchat ='Trùng hoạt chất' and chua_hoatchat <>0 then 'Pha Nam' 
       when phanloai_thuoc is not null and ndhl_clean is not null and loc_hoatchat ='Trùng hoạt chất'  and chua_hoatchat <>0 then 'Giống' 
       when (phanloai_thuoc is not null or ndhl_clean is not null) and loc_hoatchat ='Trùng hoạt chất' and chua_hoatchat <>0  then 'Tương tự' 
       else 'Không trùng hoạt chất' end as phanloai_thuoc1,
       c.nhom,
       Case when loc_hoatchat <>'Trùng hoạt chất' then null else phanloai_thuoc end as sp_merap
   from result1 a

  LEFT JOIN loc_sdk b on a.tenthuoc = b.tenthuoc and a.tencososanxuat =b.tencososanxuat
 LEFT JOIN nhom_thuoc c on a.tenthuoc = c.tenthuoc and a.tencososanxuat =c.tencososanxuat
--  where ngayqdtrungthau >='2022-01-01'
  )

  select * from result2
-- where chua_hoatchat =0  and ( Case when chua_hoatchat =0 then null else phanloai_thuoc end) is not null
  );
Create or replace table `warehouse.f_update_tinhhinh_sp_canhtranh_thau`

copy `staging_temp.f_update_tinhhinh_sp_canhtranh_thau_temp`;

End;