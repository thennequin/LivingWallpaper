
#ifndef __GL_SHADER_H__
#define __GL_SHADER_H__

#include <string>
#include "gl\glew.h"
#include <gl\GL.h>

class GLShader
{
public:
	enum EType
	{
		E_TYPE_VERTEX,
		E_TYPE_FRAGMENT
	};

	GLShader(EType eType, const char* pShader);
	~GLShader();

	void			SetShader(const char* pShader);
	bool			Compile();
	GLuint			GetShaderId() const { return m_iShaderId; }
protected:
	EType			m_eType;
	std::string		m_sShader;
	GLuint			m_iShaderId;
};

#endif //__GL_SHADER_H__