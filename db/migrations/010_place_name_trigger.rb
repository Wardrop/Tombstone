Sequel.migration do
  up do
    add_column :place, :full_name, :nvarchar, :size => 1024
    self << "SET ANSI_NULLS ON"
    self << "SET QUOTED_IDENTIFIER ON"
    self << "
      CREATE TRIGGER dbo.flattenPlaceName
         ON  PLACE
         FOR INSERT, UPDATE
      AS
      IF UPDATE(NAME)
      BEGIN
          SET NOCOUNT ON;
       
          /*Update calling Row's FULL_NAME with NAME if this is a Root level place*/
          UPDATE PLACE
          SET PLACE.FULL_NAME = PLACE.NAME
          FROM PLACE
          INNER JOIN INSERTED ON PLACE.ID = INSERTED.ID
          WHERE PLACE.PARENT_ID IS NULL; /*NULL PARENT_ID guarantees Root Level Place*/
       
          /*Update calling Row's FULL_NAME with PARENT_NAME + ' > ' + NAME if this is NOT a Root level place*/
          UPDATE PLACE
          SET PLACE.FULL_NAME = Parent.FULL_NAME + ' > ' + PLACE.NAME
          FROM PLACE
          INNER JOIN INSERTED ON PLACE.ID = INSERTED.ID
          INNER JOIN PLACE AS PARENT ON PLACE.PARENT_ID = Parent.ID; /*INNER JOIN Guarantees NOT Root Level Place*/
       
       
          /*The recursive function to get place tree*/
          WITH PlaceChildren (ID, Parent_ID, Flat_Place)
          AS
          (
              SELECT Parent_Place.ID, Parent_Place.PARENT_ID, CAST(Parent_Place.NAME as nvarchar(1024))
              FROM PLACE AS Parent_Place
              INNER JOIN INSERTED ON Parent_Place.PARENT_ID = INSERTED.ID
              UNION ALL
              SELECT Child_Place.ID, a.Parent_ID, CAST((CAST(a.Flat_Place as nvarchar(1024)) + CAST(' > ' as nvarchar) + CAST(Child_Place.NAME as nvarchar)) as nvarchar(1024))
              FROM PLACE as Child_Place
              INNER JOIN PlaceChildren AS a
                    ON Child_Place.parent_id = a.ID
              WHERE Child_Place.parent_id = a.id
          )
       
          /*Update Child places FULL_NAME with parent FULL_NAME + ' > ' + NAME if this is NOT a Root level place*/
          UPDATE PLACE
          SET PLACE.FULL_NAME =  Parent.FULL_NAME + ' > ' + Child.Flat_Place
          FROM PLACE
          INNER JOIN PlaceChildren AS Child ON PLACE.ID = Child.ID /*INNER JOIN Guarantees NOT Root Level Place*/
          INNER JOIN PLACE AS PARENT ON Child.PARENT_ID = Parent.ID /*MUST join on Child's PARENT_ID as this refers to the recursion root*/
       
      END"
      
      self << "UPDATE place SET name = name + '!' WHERE parent_id IS NULL"
      self << "UPDATE place SET name = LEFT(name, LEN(name) - 1) WHERE parent_id IS NULL"
  end
  
  down do
    self << "DROP TRIGGER dbo.flattenPlaceName"
    drop_column :place, :full_name
  end
end