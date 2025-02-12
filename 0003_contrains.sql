alter table igor.measurment_batch
add constraint users_id_contraint
foreign key (users_id)
references igor.users(id);


alter table igor.measurment_params
add constraint measurment_type_id_contraint
foreign key (measurment_type_id)
references igor.measurment_type(id);


alter table igor.measurment_params
add constraint measurment_batch_id_contraint
foreign key (measurment_batch_id)
references igor.measurment_batch(id);




select * from igor.users inner join igor.measurment_batch on igor.measurment_batch.users_id = igor.users.id;


select * from igor.measurment_params inner join igor.measurment_batch on igor.measurment_batch.id = igor.measurment_params.measurment_batch_id;