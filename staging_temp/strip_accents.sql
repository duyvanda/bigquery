CREATE FUNCTION `spatial-vision-343005`.staging_temp.strip_accents(name STRING) RETURNS STRING
AS (
TRANSLATE(
    name, 
    "àáãảạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệđùúủũụưừứửữựòóỏõọôồốổỗộơờớởỡợìíỉĩịäëïîöüûñçýỳỹỵỷÀÁÃẢẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆĐÙÚỦŨỤƯỪỨỬỮỰÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÌÍỈĨỊÄËÏÎÖÜÛÑÇÝỲỸỴỶ", 
    "aaaaaaaaaaaaaaaaaeeeeeeeeeeeduuuuuuuuuuuoooooooooooooooooiiiiiaeiiouuncyyyyyaaaaaaaaaaaaaaaaaeeeeeeeeeeeDuuuuuuuuuuuoooooooooooooooooiiiiiaeiiouuncyyyyy"
  )
);