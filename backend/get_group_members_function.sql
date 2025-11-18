-- Funcție pentru a obține toți membrii unui grup (bypass RLS)
CREATE OR REPLACE FUNCTION get_group_members_for_assignment(p_group_id UUID)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT
)
SECURITY DEFINER -- Aceasta permite bypass-ul RLS
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verifică dacă user-ul curent este membru al grupului
  IF NOT EXISTS (
    SELECT 1 FROM group_members 
    WHERE group_id = p_group_id 
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User is not a member of this group';
  END IF;

  -- Returnează toți membrii grupului cu informațiile lor
  RETURN QUERY
  SELECT 
    gm.user_id,
    u.email,
    u.full_name
  FROM group_members gm
  JOIN users u ON u.id = gm.user_id
  WHERE gm.group_id = p_group_id
  ORDER BY u.full_name, u.email;
END;
$$;

-- Acordă permisiuni de execuție utilizatorilor autentificați
GRANT EXECUTE ON FUNCTION get_group_members_for_assignment(UUID) TO authenticated;
