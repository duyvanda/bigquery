CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_sellers_registered_acc_perfor()
BEGIN 
     TRUNCATE TABLE staging_temp.f_sellers_registered_acc_perfor_temp;

     INSERT INTO staging_temp.f_sellers_registered_acc_perfor_temp

(
               with base as
               (select
               t1.ngaychungtu, 
               t1.sodondathang, 
               -- t1.mahd,
               -- t1.trangthai,
               t1.makhdms, 
               -- t1.makhcu, 
               t1.tenkhachhang, 
               -- t1.tenvungbh,
               -- t1.tenkhuvuc,
               -- t1.makenhkh,
               -- t1.tenkenhkh,
               -- t1.makenhphu, 
               -- t1.tenkenhphu, 
               -- t1.mahco, 
               -- t1.tenhco, 
               -- t1.maphanloaihco, 
               -- t1.tenphanloaihco, 
               -- t1.maphanhanghco, 
               -- t1.tenphanhanghco, 
               -- t1.tensanphamnb, 
               -- t1.masanpham,
               t1.tentinhkh,
               t1.manv,
               t1.tencvbh,
               t2.supid,
               t2.tenquanlytt,
               t2.asm,
               t2.tenquanlykhuvuc,
               t2.rsmid,
               case when t2.tenquanlyvung in ('Nguyễn Hoàng Viển','Bùi Hữu Toàn','Nguyễn Thọ Chiến') then t2.tenquanlyvung else 'Chưa xác định' end tenquanlyvung,


               -- ,
               sum(t1.doanhsochuavat) doanhsochuavat,
               sum(t1.soluong) soluong

               from `spatial-vision-343005.staging.f_sales` t1
               left join `spatial-vision-343005.staging.d_users` t2 on t1.manv = t2.manv


               where t1.tencvbh <> 'Phạm Thị Quỳnh Ảo' and doanhsochuavat!=0 and date(ngaychungtu)>=date_trunc(date_sub(current_date, interval 3 month),month)
               group by 1,2,3,4,5,6,7,8,9,10,11,12,13
               )



               select t1.*
               ,ifnull(MR_acc_registered,'Không đăng ký') MR_acc_registered, ifnull(PN_acc_registered,'Không đăng ký') PN_acc_registered

               from base t1
               ----------- Danh sách đk TLQ
               left join (SELECT custid
                              , if(sum(case when t1.accumulateid like '%/MR%' then 1 else 0 end)>0,'Có đăng ký','Không đăng ký') MR_acc_registered
                              ,if(sum(case when t1.accumulateid like '%/PN%' then 1 else 0 end)>0,'Có đăng ký','Không đăng ký') PN_acc_registered
                         FROM `spatial-vision-343005.staging.d_accumulated` t1
                         left join staging.d_accumulatedregis t2 
                                                       on t1.AccumulateID=t2.AccumulateID and t2.crtd_datetime between t1.fromdate and t1.todate
                         where date_trunc(case when current_timestamp between fromdate and todate then current_timestamp else t2.crtd_datetime end ,quarter ) = date_trunc(current_timestamp,quarter)
                         group by 1 
                         ) t5 
                              on t1.makhdms=t5.custid
               
);

Create or replace table `staging_temp.f_sellers_registered_acc_perfor`

copy `staging_temp.f_sellers_registered_acc_perfor_temp`;

END;